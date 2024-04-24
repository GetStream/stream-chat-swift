//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ChannelListState {
    final class Observer {
        private let channelListObserver: StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO>
        private let clientConfig: ChatClientConfig
        private let channelListUpdater: ChannelListUpdater
        private let database: DatabaseContainer
        private let dynamicFilter: ((ChatChannel) -> Bool)?
        private let eventNotificationCenter: EventNotificationCenter
        private var eventObservers = [EventObserver]()
        private let query: ChannelListQuery
        
        init(
            query: ChannelListQuery,
            dynamicFilter: ((ChatChannel) -> Bool)?,
            clientConfig: ChatClientConfig,
            channelListUpdater: ChannelListUpdater,
            database: DatabaseContainer,
            eventNotificationCenter: EventNotificationCenter
        ) {
            self.clientConfig = clientConfig
            self.channelListUpdater = channelListUpdater
            self.database = database
            self.dynamicFilter = dynamicFilter
            self.query = query
            self.eventNotificationCenter = eventNotificationCenter
            
            channelListObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: ChannelDTO.channelListFetchRequest(
                    query: query,
                    chatClientConfig: clientConfig
                ),
                itemCreator: { try $0.asModel() as ChatChannel },
                sorting: query.sort.runtimeSorting
            )
        }
        
        struct Handlers {
            let channelsDidChange: (StreamCollection<ChatChannel>) async -> Void
        }
        
        func start(with handlers: Handlers) -> StreamCollection<ChatChannel> {
            /// When we receive events, we need to check if a channel should be added or removed from
            /// the current query depending on the following events:
            /// - Channel created: We analyse if the channel should be added to the current query.
            /// - New message sent: This means the channel will reorder and appear on first position,
            ///   so we also analyse if it should be added to the current query.
            /// - Channel is updated: We only check if we should remove it from the current query.
            ///   We don't try to add it to the current query to not mess with pagination.
            let nc = eventNotificationCenter
            eventObservers = [
                EventObserver(
                    notificationCenter: nc,
                    transform: { $0 as? NotificationAddedToChannelEvent }
                ) { [weak self] event in
                    try await self?.linkChannelIfNeeded(event.channel)
                },
                EventObserver(
                    notificationCenter: nc,
                    transform: { $0 as? MessageNewEvent },
                    callback: { [weak self] event in
                        try await self?.linkChannelIfNeeded(event.channel)
                    }
                ),
                EventObserver(
                    notificationCenter: nc,
                    transform: { $0 as? NotificationMessageNewEvent },
                    callback: { [weak self] event in
                        try await self?.linkChannelIfNeeded(event.channel)
                    }
                ),
                EventObserver(
                    notificationCenter: nc,
                    transform: { $0 as? ChannelUpdatedEvent },
                    callback: { [weak self] event in
                        try await self?.unlinkChannelIfNeeded(event.channel)
                    }
                ),
                EventObserver(
                    notificationCenter: nc,
                    transform: { $0 as? ChannelVisibleEvent },
                    callback: { [weak self] event in
                        guard let self else { return }
                        let channel = try await self.database.read { context in
                            guard let dto = ChannelDTO.load(cid: event.cid, context: context) else {
                                throw ClientError.ChannelDoesNotExist(cid: event.cid)
                            }
                            return try dto.asModel()
                        }
                        try await self.linkChannelIfNeeded(channel)
                    }
                )
            ]
            
            do {
                return try channelListObserver.startObserving(didChange: handlers.channelsDidChange)
            } catch {
                log.error("Failed to start the channel list observer for query: \(query)")
                return StreamCollection([])
            }
        }
        
        // MARK: Linking and Unlinking Channels from the Query
        
        private func isBelongingToChannelListQuery(channel: ChatChannel) -> Bool {
            if let filter = dynamicFilter {
                return filter(channel)
            }
            // When auto-filtering is enabled the channel will appear or not automatically if the
            // query matches the DB Predicate. So here we default to saying it always belong to the current query.
            if clientConfig.isChannelAutomaticFilteringEnabled {
                return true
            }
            return false
        }
        
        private func isChannelInList(_ cid: ChannelId) async throws -> Bool {
            try await database.read { [query] context in
                guard let (channelDTO, queryDTO) = context.getChannelWithQuery(cid: cid, query: query) else { return false }
                return queryDTO.channels.contains(channelDTO)
            }
        }
        
        private func linkChannelIfNeeded(_ channel: ChatChannel) async throws {
            let listContainsChannel = try await isChannelInList(channel.cid)
            guard !listContainsChannel else { return }
            guard isBelongingToChannelListQuery(channel: channel) else { return }
            try await channelListUpdater.link(channel: channel, with: query)
            try await channelListUpdater.startWatchingChannels(withIds: [channel.cid])
        }
        
        private func unlinkChannelIfNeeded(_ channel: ChatChannel) async throws {
            let listContainsChannel = try await isChannelInList(channel.cid)
            guard listContainsChannel else { return }
            guard !isBelongingToChannelListQuery(channel: channel) else { return }
            try await channelListUpdater.unlink(channel: channel, with: query)
        }
    }
}
