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
/// Membership is decided purely from the channel's `"group"` extra-data value:
/// - The ``GroupedChannelKey/all`` query is a catch-all: every channel carrying any non-empty group
///   value links into it.
/// - Any other `groupKey` links a channel only when its `"group"` value (whitespace-trimmed and
///   lowercased) equals the query's `groupKey`; otherwise the channel is unlinked.
final class GroupedChannelListLinker: Sendable, ChannelListLinking {
    private let channelWatcherHandler: ChannelWatcherHandling
    private let databaseContainer: DatabaseContainer
    private nonisolated(unsafe) var eventObservers = [EventObserver]()
    private let query: ChannelListQuery

    init(
        query: ChannelListQuery,
        databaseContainer: DatabaseContainer,
        channelWatcherHandler: ChannelWatcherHandling
    ) {
        self.channelWatcherHandler = channelWatcherHandler
        self.databaseContainer = databaseContainer
        self.query = query
    }

    func start(with nc: EventNotificationCenter) {
        guard eventObservers.isEmpty else { return }
        eventObservers = [
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationAddedToChannelEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? MessageNewEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationMessageNewEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelUpdatedEvent },
                callback: { [weak self] event in self?.updateLinking(for: event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelVisibleEvent },
                callback: { [weak self, databaseContainer] event in
                    let context = databaseContainer.backgroundReadOnlyContext
                    context.perform { [self] in
                        guard let channel = try? context.channel(cid: event.cid)?.asModel() else { return }
                        self?.updateLinking(for: channel)
                    }
                }
            )
        ]
    }

    /// Links or unlinks the channel for the current grouped query in a single DB write, based on
    /// whether it should belong to the query and whether it is already part of the list.
    /// After a fresh link, starts watching the channel when the query was issued with
    /// ``QueryOptions/watch`` and the channel isn't already linked to another query.
    private func updateLinking(for channel: ChatChannel) {
        let shouldBelong = shouldChannelBelongToCurrentQuery(channel)
        databaseContainer.write(converting: { [query] session -> Bool in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else { return false }
            let isInList = queryDTO.channels.contains(channelDTO)
            if shouldBelong, !isInList {
                // Channel isn't linked to any query yet, so it isn't already being watched.
                let shouldStartWatching = queryDTO.watch && channelDTO.queries.isEmpty
                queryDTO.channels.insert(channelDTO)
                return shouldStartWatching
            } else if !shouldBelong, isInList {
                queryDTO.channels.remove(channelDTO)
            }
            return false
        }, completion: { [channelWatcherHandler, cid = channel.cid] result in
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

    /// Checks if the given channel should belong to the current query or not.
    ///
    /// Empty or missing `"group"` extra-data resolves to `false` — without a filter to fall back to,
    /// the safest move is to unlink rather than leave stale links behind after a `ChannelUpdatedEvent`.
    private func shouldChannelBelongToCurrentQuery(_ channel: ChatChannel) -> Bool {
        let currentGroupKey = channel.extraData[GroupedChannelKey.group]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let currentGroupKey, !currentGroupKey.isEmpty else { return false }
        return query.groupKey == currentGroupKey || query.groupKey == GroupedChannelKey.all
    }
}
