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
/// - Channel is hidden, deleted, disabled, or the current user was removed from it: the backend
///   leaves it out of grouped queries, so it is unlinked. Channel visible re-links it.
///
/// Only channels the current user is a member of are linked, and the channel's `"group"` extra-data value decides where:
/// - The ``GroupedChannelKey/all`` query is a catch-all: every channel links into it, including channels without a group.
/// - Any other `groupKey` links a channel only when its `"group"` value equals the query's `groupKey`;
///   otherwise the channel is unlinked.
///
/// When the group was queried with a filter, the channel must also match it, evaluated as a Core Data predicate.
/// The backend sends no event when a channel passes a `query_timestamp` cutoff, so linked channels are
/// re-checked periodically and unlinked once they no longer match. Reconnect sync re-checks them too,
/// because the events it replays are not posted.
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
                transform: { $0 as? ChannelHiddenEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.cid) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelDeletedEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.cid) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationChannelDeletedEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.cid) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationRemovedFromChannelEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.cid, isMember: false) }
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
        } else if Self.isInGroup(event.group, groupKey: query.groupKey) {
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
            try Self.unlinkChannelsNotBelonging(to: query, session: session)
        }, completion: { error in
            guard let error else { return }
            log.error(error)
        })
    }

    static func unlinkChannelsNotBelonging(to query: ChannelListQuery, session: DatabaseSession) throws {
        guard let queryDTO = session.channelListQuery(query) else { return }
        let filterPredicate = try filterPredicate(of: queryDTO)
        let unlinked = queryDTO.channels.filter { !belongs($0, to: query.groupKey, filterPredicate: filterPredicate) }
        guard !unlinked.isEmpty else { return }
        queryDTO.channels.subtract(unlinked)
        session.updateFilteredGroupUnreadChannelCounts(for: [queryDTO])
    }

    /// Links or unlinks the channel for the current grouped query in a single DB write, based on
    /// whether it should belong to the query and whether it is already part of the list.
    /// After a fresh link, starts watching the channel when the query was issued with
    /// ``QueryOptions/watch`` and the channel isn't already linked to another query.
    private func updateLinking(for cid: ChannelId, isNewMessage: Bool = false, isMember: Bool = true, startsWatching: Bool = true) {
        databaseContainer.write(converting: { [query] session -> Bool in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: cid, query: query) else { return false }
            let shouldBelong = try isMember && Self.belongs(channelDTO, to: query.groupKey, filterPredicate: Self.filterPredicate(of: queryDTO))
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

    private static func belongs(_ channelDTO: ChannelDTO, to groupKey: String?, filterPredicate: NSPredicate?) -> Bool {
        let canShowChannel = !channelDTO.isHidden && !channelDTO.isDisabled && channelDTO.deletedAt == nil
        let isMemberInGroup = channelDTO.membership != nil && isInGroup(channelDTO.group, groupKey: groupKey)
        return canShowChannel && isMemberInGroup && (filterPredicate?.evaluate(with: channelDTO) ?? true)
    }

    private static func isInGroup(_ group: String?, groupKey: String?) -> Bool {
        groupKey == GroupedChannelKey.all || (group != nil && groupKey == group)
    }

    private static func filterPredicate(of queryDTO: ChannelListQueryDTO) throws -> NSPredicate? {
        try queryDTO.groupFilterJSONData.flatMap { try Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: $0)?.predicate }
    }
}
