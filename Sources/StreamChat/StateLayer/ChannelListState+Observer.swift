//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelListState {
    final class Observer {
        private let channelListObserver: StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO>
        private let clientConfig: ChatClientConfig
        private let channelListLinker: ChannelListLinker
        private let channelListUpdater: ChannelListUpdater
        private let database: DatabaseContainer
        private let dynamicFilter: ((ChatChannel) -> Bool)?
        private let eventNotificationCenter: EventNotificationCenter
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
                database: database,
                fetchRequest: ChannelDTO.channelListFetchRequest(
                    query: query,
                    chatClientConfig: clientConfig
                ),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
                sorting: query.sort.runtimeSorting
            )
            channelListLinker = ChannelListLinker(
                query: query,
                filter: dynamicFilter,
                clientConfig: clientConfig,
                databaseContainer: database,
                worker: channelListUpdater
            )
        }
        
        struct Handlers {
            let channelsDidChange: @MainActor(StreamCollection<ChatChannel>) async -> Void
        }
        
        func start(with handlers: Handlers) -> StreamCollection<ChatChannel> {
            do {
                channelListLinker.start(with: eventNotificationCenter)
                return try channelListObserver.startObserving(didChange: handlers.channelsDidChange)
            } catch {
                log.error("Failed to start the channel list observer for query: \(query)")
                return StreamCollection([])
            }
        }
    }
}
