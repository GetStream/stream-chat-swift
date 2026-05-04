//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelListState {
    @MainActor final class Observer {
        private var channelListObserver: StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO>?
        private let clientConfig: ChatClientConfig
        private var channelListLinker: ChannelListLinker?
        private let channelListUpdater: ChannelListUpdater
        private let channelWatcherHandler: ChannelWatcherHandling
        private let database: DatabaseContainer
        private let dynamicFilter: (@Sendable (ChatChannel) -> Bool)?
        private let eventNotificationCenter: EventNotificationCenter
        
        init(
            dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
            clientConfig: ChatClientConfig,
            channelListUpdater: ChannelListUpdater,
            database: DatabaseContainer,
            eventNotificationCenter: EventNotificationCenter,
            channelWatcherHandler: ChannelWatcherHandling
        ) {
            self.clientConfig = clientConfig
            self.channelListUpdater = channelListUpdater
            self.database = database
            self.dynamicFilter = dynamicFilter
            self.eventNotificationCenter = eventNotificationCenter
            self.channelWatcherHandler = channelWatcherHandler
        }
        
        struct Handlers {
            let channelsDidChange: @Sendable @MainActor ([ChatChannel]) async -> Void
        }
        
        func start(
            observing query: ChannelListQuery,
            minimumFetchLimit: Int = 0,
            handlers: Handlers
        ) -> [ChatChannel] {
            channelListObserver?.stopObserving()

            let fetchRequest = ChannelDTO.channelListFetchRequest(
                query: query,
                chatClientConfig: clientConfig
            )
            let fetchLimit = max(query.pagination.pageSize, minimumFetchLimit)
            fetchRequest.fetchLimit = fetchLimit
            fetchRequest.fetchBatchSize = fetchLimit

            let channelListObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: fetchRequest,
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
                runtimeSorting: query.runtimeSortingValues
            )
            self.channelListObserver = channelListObserver
            channelListLinker = ChannelListLinker(
                query: query,
                filter: dynamicFilter,
                clientConfig: clientConfig,
                databaseContainer: database,
                worker: channelListUpdater,
                channelWatcherHandler: channelWatcherHandler
            )

            do {
                channelListLinker?.start(with: eventNotificationCenter)
                return try channelListObserver.startObserving(didChange: handlers.channelsDidChange)
            } catch {
                log.error("Failed to start the channel list observer for query: \(query)")
                return []
            }
        }
    }
}
