//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// When we receive events, we need to check if a channel should be added or removed from
/// the current group-based query depending on the following events:
/// - Channel created: We analyse if the channel should be added to the current group.
/// - New message sent: This means the channel will reorder and appear on first position,
///   so we also analyse if it should be added to the current group.
/// - Channel is updated: We re-evaluate membership — the channel's `"group"` extra-data may have
///   changed, which can move it into or out of this query.
///
/// Membership is decided from the channel's `"group"` extra-data value:
/// - The ``GroupedChannelKey/all`` query is a catch-all: every channel carrying any non-empty group
///   value links into it.
/// - Any other `groupKey` links a channel only when its `"group"` value equals the query's `groupKey`;
///   otherwise the channel is unlinked.
///
/// When the group was queried with a filter, the channel must also match it, evaluated as a Core Data predicate.
/// The backend sends no event when a channel passes a `query_timestamp` cutoff, so linked channels are
/// re-checked periodically and unlinked once they no longer match.
final class GroupedChannelListLinker: Sendable, ChannelListLinking {
    private let channelWatcherHandler: ChannelWatcherHandling
    private let databaseContainer: DatabaseContainer
    private nonisolated(unsafe) var eventObservers = [EventObserver]()
    private nonisolated(unsafe) var expirySweepTimer: RepeatingTimerControl?
    private let query: ChannelListQuery
    private nonisolated(unsafe) let timerType: TimerScheduling.Type

    init(
        query: ChannelListQuery,
        databaseContainer: DatabaseContainer,
        channelWatcherHandler: ChannelWatcherHandling,
        timerType: TimerScheduling.Type = DefaultTimer.self
    ) {
        self.channelWatcherHandler = channelWatcherHandler
        self.databaseContainer = databaseContainer
        self.query = query
        self.timerType = timerType
    }

    func start(with nc: EventNotificationCenter) {
        guard eventObservers.isEmpty else { return }
        eventObservers = [
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationAddedToChannelEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel.cid) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? MessageNewEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel.cid, isNewMessage: true) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationMessageNewEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel.cid, isNewMessage: true) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelUpdatedEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel.cid) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelVisibleEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.cid) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationChannelPartialUpdatedEvent },
                callback: { [weak self] event in self?.handlePartialUpdate(event) }
            )
        ]
        expirySweepTimer = timerType.scheduleRepeating(
            timeInterval: 60,
            queue: .global(qos: .utility),
            onFire: { [weak self] in self?.removeExpiredChannels() }
        )
        expirySweepTimer?.resume()
    }

    private func handlePartialUpdate(_ event: NotificationChannelPartialUpdatedEvent) {
        if event.isChannelStored {
            updateLinking(for: event.cid)
        } else if let group = event.group, query.groupKey == GroupedChannelKey.all || query.groupKey == group {
            // Watching fetches and saves the channel, then it can be linked to the query.
            databaseContainer.read({ [query] session in
                session.channelListQuery(query)?.watch == true
            }, completion: { [weak self, cid = event.cid] result in
                if case .success(true) = result {
                    self?.channelWatcherHandler.attemptToWatch(channelIds: [cid]) { [weak self] error in
                        if let error {
                            log.warning("Failed to start watching partially updated channel: \(cid), error: \(error.localizedDescription)")
                        } else {
                            self?.updateLinking(for: cid, startsWatching: false)
                        }
                    }
                }
            })
        }
    }

    private func removeExpiredChannels() {
        databaseContainer.write({ [query] session in
            guard let queryDTO = session.channelListQuery(query),
                  let filterPredicate = try self.filterPredicate(of: queryDTO) else { return }
            let expired = queryDTO.channels.filter { !filterPredicate.evaluate(with: $0) }
            guard !expired.isEmpty else { return }
            queryDTO.channels.subtract(expired)
            session.updateFilteredGroupUnreadChannelCounts(for: [queryDTO])
        }, completion: { error in
            guard let error else { return }
            log.error(error)
        })
    }

    /// Links or unlinks the channel for the current grouped query in a single DB write, based on
    /// whether it should belong to the query and whether it is already part of the list.
    /// After a fresh link, starts watching the channel when the query was issued with
    /// ``QueryOptions/watch`` and the channel isn't already linked to another query.
    private func updateLinking(for cid: ChannelId, isNewMessage: Bool = false, startsWatching: Bool = true) {
        databaseContainer.write(converting: { [query] session -> Bool in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: cid, query: query) else { return false }
            let isInGroup = channelDTO.group != nil && (query.groupKey == GroupedChannelKey.all || query.groupKey == channelDTO.group)
            let shouldBelong = try isInGroup && (self.filterPredicate(of: queryDTO)?.evaluate(with: channelDTO) ?? true)
            let isInList = queryDTO.channels.contains(channelDTO)
            if shouldBelong, !isInList {
                // Channel isn't linked to any query yet, so it isn't already being watched.
                let shouldStartWatching = startsWatching && queryDTO.watch && channelDTO.queries.isEmpty
                queryDTO.channels.insert(channelDTO)
                // A channel that was already unread before this message was counted as not loaded.
                if isNewMessage, queryDTO.groupFilterJSONData != nil, let currentUserId = session.currentUser?.user.id,
                   ChannelListQueryDTO.unreadMessageCount(of: channelDTO, currentUserId: currentUserId) > 1 {
                    queryDTO.groupNotLoadedUnreadCount = max(0, queryDTO.groupNotLoadedUnreadCount - 1)
                }
                session.updateFilteredGroupUnreadChannelCounts(for: [queryDTO])
                return shouldStartWatching
            } else if !shouldBelong, isInList {
                queryDTO.channels.remove(channelDTO)
                session.updateFilteredGroupUnreadChannelCounts(for: [queryDTO])
            }
            return false
        }, completion: { [channelWatcherHandler] result in
            switch result {
            case .failure(let error):
                log.error(error)
            case .success(let shouldStartWatching):
                guard shouldStartWatching else { return }
                channelWatcherHandler.attemptToWatch(channelIds: [cid]) { error in
                    guard let error else { return }
                    log.warning("Failed to start watching linked channel: \(cid), error: \(error.localizedDescription)")
                }
            }
        })
    }

    private func filterPredicate(of queryDTO: ChannelListQueryDTO) throws -> NSPredicate? {
        try queryDTO.groupFilterJSONData.flatMap { try Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: $0)?.predicate }
    }
}
