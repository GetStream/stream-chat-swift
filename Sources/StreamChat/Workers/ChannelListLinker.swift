//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Subscribes to channel-relevant WS events and links / unlinks channels for the owning query.
///
/// Each observer declares an `allowedActions` set that bounds what `linkingAction(for:)` may decide:
/// - ``NotificationAddedToChannelEvent``, ``MessageNewEvent``, ``NotificationMessageNewEvent``, ``ChannelVisibleEvent`` — link-only.
///   Membership/visibility gained or activity arrived; never an unlink trigger.
/// - ``ChannelUpdatedEvent`` — link or unlink. Channel metadata changed (filter-matching attributes, the
///   `"group"` extra-data value), which can move the channel into or out of this query.
///
/// `linkingAction(for:)` resolves the decision against the query type:
/// - Group-based queries (`query.groupKey != nil`) match `channel.extraData["group"]` against ``GroupedChannelKey/all``
///   or the query's `groupKey`.
/// - Filter-based queries either run the optional in-memory `filter` block, or — when automatic filtering
///   is enabled in `ChatClientConfig` — defer to the DB fetch predicate and always link.
final class ChannelListLinker: Sendable {
    private let clientConfig: ChatClientConfig
    private let databaseContainer: DatabaseContainer
    private nonisolated(unsafe) var eventObservers = [EventObserver]()
    private let filter: (@Sendable (ChatChannel) -> Bool)?
    private let query: ChannelListQuery
    private let worker: ChannelListUpdater
    private let channelWatcherHandler: ChannelWatcherHandling

    init(
        query: ChannelListQuery,
        filter: (@Sendable (ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        databaseContainer: DatabaseContainer,
        worker: ChannelListUpdater,
        channelWatcherHandler: ChannelWatcherHandling
    ) {
        self.clientConfig = clientConfig
        self.databaseContainer = databaseContainer
        self.filter = filter
        self.query = query
        self.worker = worker
        self.channelWatcherHandler = channelWatcherHandler
    }
    
    func start(with nc: EventNotificationCenter) {
        guard eventObservers.isEmpty else { return }
        eventObservers = [
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationAddedToChannelEvent },
                callback: { [weak self] event in
                    self?.handle(channel: event.channel, allowedActions: [.link])
                }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? MessageNewEvent },
                callback: { [weak self] event in
                    self?.handle(channel: event.channel, allowedActions: [.link])
                }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationMessageNewEvent },
                callback: { [weak self] event in
                    self?.handle(channel: event.channel, allowedActions: [.link])
                }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelUpdatedEvent },
                callback: { [weak self] event in
                    self?.handle(channel: event.channel, allowedActions: [.link, .unlink])
                }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelVisibleEvent },
                callback: { [weak self, databaseContainer] event in
                    let context = databaseContainer.backgroundReadOnlyContext
                    context.perform { [self] in
                        guard let channel = try? context.channel(cid: event.cid)?.asModel() else { return }
                        self?.handle(channel: channel, allowedActions: [.link])
                    }
                }
            )
        ]
    }

    private func handle(channel: ChatChannel, allowedActions: Set<LinkingAction>) {
        let action = linkingAction(for: channel)
        
        switch action {
        case .link where allowedActions.contains(.link):
            linkChannel(channel)
        case .unlink where allowedActions.contains(.unlink):
            unlinkChannel(channel)
        default:
            break
        }
    }
    
    private func isInChannelList(
        _ channel: ChatChannel,
        completion: @escaping @Sendable (_ isPresent: Bool, _ belongsToOtherQuery: Bool) -> Void
    ) {
        let context = databaseContainer.backgroundReadOnlyContext
        context.performAndWait { [weak self] in
            guard let self else { return }
            if let (channelDTO, queryDTO) = context.getChannelWithQuery(cid: channel.cid, query: self.query) {
                let isPresent = queryDTO.channels.contains(channelDTO)
                let belongsToOtherQuery = channelDTO.queries.count > 0
                completion(isPresent, belongsToOtherQuery)
            } else {
                completion(false, false)
            }
        }
    }
    
    private func linkChannel(_ channel: ChatChannel) {
        isInChannelList(channel) { [worker, query, channelWatcherHandler] exists, belongsToOtherQuery in
            guard !exists else { return }
            worker.link(channel: channel, with: query) { error in
                if let error = error {
                    log.error(error)
                    return
                }

                // If it belongs to another query, it means it is already being watched.
                guard !belongsToOtherQuery else { return }
                
                // Watch the channel, handler will prevent duplicate requests.
                channelWatcherHandler.attemptToWatch(channelIds: [channel.cid]) { error in
                    guard let error = error else { return }
                    log.warning(
                        "Failed to start watching linked channel: \(channel.cid), error: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    private func unlinkChannel(_ channel: ChatChannel) {
        isInChannelList(channel) { [worker, query] exists, _ in
            guard exists else { return }
            worker.unlink(channel: channel, with: query)
        }
    }

    /// Decides whether `channel` should be linked into the current query, unlinked from it, or left alone.
    ///
    /// The decision branches on whether the query is **group-based** or **filter-based**.
    ///
    /// ## Group-based queries (`query.groupKey != nil`)
    ///
    /// Group-based queries are produced by the `/grouped_channels` endpoint and carry **no filter
    /// predicate**: ``ChannelListQuery/init(groupKey:)`` constructs them with `filter: .empty`, and
    /// the backend decides membership purely from the channel's `"group"` extra-data value.
    /// Linking here is therefore driven **only** by ``GroupedChannelKey/extraData`` ("group") on
    /// the channel — no in-memory filter is consulted and no DB predicate is involved.
    ///
    /// - The special ``GroupedChannelKey/all`` query is a catch-all: every channel that has *any*
    ///   non-empty group value links into it. This mirrors the backend, which always returns the
    ///   `"all"` bucket alongside the requested groups.
    /// - Any other `groupKey` links a channel only when its `"group"` value (whitespace-trimmed
    ///   and lowercased) equals the query's `groupKey`; otherwise the channel is unlinked.
    /// - Channels with a missing or empty `"group"` value resolve to ``LinkingAction/none``: with
    ///   no filter to fall back to, the safest move is to leave the query untouched rather than
    ///   guess.
    ///
    /// ## Filter-based queries (`query.groupKey == nil`)
    ///
    /// - When an in-memory `filter` block is supplied, it is the single source of truth: link on
    ///   `true`, unlink on `false`.
    /// - Otherwise, when ``ChatClientConfig/isChannelAutomaticFilteringEnabled`` is on, the DB
    ///   fetch predicate already governs visibility, so we always link and let the predicate
    ///   filter on read.
    /// - With neither in place, the function returns ``LinkingAction/none``.
    private func linkingAction(for channel: ChatChannel) -> LinkingAction {
        if let groupKey = query.groupKey {
            // Group-based queries have no filter predicate; membership is decided entirely from
            // the channel's "group" extra-data value. The "all" group is a catch-all that links
            // every channel carrying any non-empty group value.
            let currentGroupKey = channel.extraData[GroupedChannelKey.extraData]?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let currentGroupKey, !currentGroupKey.isEmpty {
                return groupKey == currentGroupKey || groupKey == GroupedChannelKey.all ? .link : .unlink
            }
            return .none
        } else {
            if let filter = filter {
                return filter(channel) ? .link : .unlink
            }
            
            if clientConfig.isChannelAutomaticFilteringEnabled {
                // When auto-filtering is enabled the channel will appear or not automatically if the
                // query matches the DB Predicate. So here we default to saying it always belong to the current query.
                return .link
            }
            
            return .none
        }
    }
}

extension ChannelListLinker {
    enum LinkingAction {
        case link, unlink, none
    }
}
