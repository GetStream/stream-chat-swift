//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// When we receive events, we need to check if a channel should be added or removed from
/// the current query depending on the following events:
/// - Channel created: We analyse if the channel should be added to the current query.
/// - New message sent: This means the channel can reorder and also move between query-backed
///   lists, so we analyse if it should be removed from or added to the current query.
/// - Channel is updated: We analyse if it should be removed from or added to the current query.
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

    /// Checks if the given channel should belong to the current query or not.
    private func linkingAction(for channel: ChatChannel) -> LinkingAction {
        if let groupKey = query.groupKey {
            // "all" group key is special, all the other groups are always linked to it
            let currentGroupKey = channel.extraData["group"]?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let currentGroupKey, !currentGroupKey.isEmpty {
                return groupKey == currentGroupKey || groupKey == "all" ? .link : .unlink
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
