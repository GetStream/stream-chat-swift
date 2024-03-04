//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Listens to local events and adds or removes channels from ``ChannelListQueryDTO.channels``.
@available(iOS 13.0, *)
struct ChannelListQueryLinkingCoordinator {
    private let eventsController: EventsController
    private let eventsDelegate: EventsDelegate
    
    init(state: ChatListState, query: ChannelListQuery, dynamicFilter: ((ChatChannel) -> Bool)?, channelListUpdater: ChannelListUpdater, eventsController: EventsController, database: DatabaseContainer, clientConfig: ChatClientConfig) {
        self.eventsController = eventsController
        eventsDelegate = EventsDelegate(database: database)
        
        eventsController.delegate = eventsDelegate
        eventsDelegate.linkingHandler = { [weak state] channel, shouldLink in
            guard let state else { return }
            let channels = await state.value(forKeyPath: \.channels)
            let isPresent = channels.contains(where: { $0.cid == channel.cid })
            
            /// True, if the channel should be part of the current query. Used when handling local changes.
            let isQueryMatching: (ChatChannel) -> Bool = { channel in
                if let dynamicFilter {
                    return dynamicFilter(channel)
                }
                if clientConfig.isChannelAutomaticFilteringEnabled {
                    // When auto-filtering is enabled the channel will appear or not automatically if the
                    // query matches the DB Predicate. So here we default to saying it always belong to the current query.
                    return true
                }
                return channel.membership != nil
            }
            
            switch (shouldLink, isPresent) {
            case (true, false):
                guard isQueryMatching(channel) else { return }
                do {
                    try await channelListUpdater.link(channel: channel, with: query)
                    try await channelListUpdater.startWatchingChannels(withIds: [channel.cid])
                } catch {
                    log.warning("Failed to link a channel (\(channel.cid)) to query with error: \(error)")
                }
            case (false, true):
                guard !isQueryMatching(channel) else { return }
                do {
                    try await channelListUpdater.unlink(channel: channel, with: query)
                } catch {
                    log.warning("Failed to unlink a channel (\(channel.cid)) from query with error: \(error)")
                }
            default:
                break
            }
        }
    }
}

@available(iOS 13.0, *)
extension ChannelListQueryLinkingCoordinator {
    final class EventsDelegate: EventsControllerDelegate {
        let database: DatabaseContainer
        
        init(database: DatabaseContainer) {
            self.database = database
        }
        
        var linkingHandler: (ChatChannel, Bool) async -> Void = { _, _ in }
        
        /// When we receive events, we need to check if a channel should be added or removed from
        /// the current query depending on the following events:
        /// - Channel created: We analyse if the channel should be added to the current query.
        /// - New message sent: This means the channel will reorder and appear on first position,
        ///   so we also analyse if it should be added to the current query.
        /// - Channel is updated: We only check if we should remove it from the current query.
        ///   We don't try to add it to the current query to not mess with pagination.
        func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
            switch event {
            case let channelAdded as NotificationAddedToChannelEvent:
                Task { await linkingHandler(channelAdded.channel, true) }
            case let messageNewEvent as MessageNewEvent:
                Task { await linkingHandler(messageNewEvent.channel, true) }
            case let messageNewEvent as NotificationMessageNewEvent:
                Task { await linkingHandler(messageNewEvent.channel, true) }
            case let channelVisibleEvent as ChannelVisibleEvent:
                Task {
                    let channel = try await database.backgroundRead { context in
                        try ChannelDTO.load(cid: channelVisibleEvent.cid, context: context)?.asModel()
                    }
                    guard let channel else { return }
                    await linkingHandler(channel, true)
                }
            case let updatedEvent as ChannelUpdatedEvent:
                Task { await linkingHandler(updatedEvent.channel, false) }
            default:
                break
            }
        }
    }
}
