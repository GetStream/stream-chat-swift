//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelListState {
    final class Observer {
        private var channelListObserver: StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO>
        private let clientConfig: ChatClientConfig
        private var channelListLinker: ChannelListLinker
        private let channelListUpdater: ChannelListUpdater
        private let database: DatabaseContainer
        private let eventNotificationCenter: EventNotificationCenter
        private let dynamicFilter: (@Sendable (ChatChannel) -> Bool)?
        private let channelWatcherHandler: ChannelWatcherHandling
        private var query: ChannelListQuery
        private var channelsDidChange: (@Sendable @MainActor ([ChatChannel]) async -> Void)?

        init(
            query: ChannelListQuery,
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
            self.query = query
            self.eventNotificationCenter = eventNotificationCenter
            self.dynamicFilter = dynamicFilter
            self.channelWatcherHandler = channelWatcherHandler

            channelListObserver = Self.makeChannelListObserver(
                for: query,
                database: database,
                clientConfig: clientConfig
            )
            channelListLinker = Self.makeChannelListLinker(
                for: query,
                dynamicFilter: dynamicFilter,
                clientConfig: clientConfig,
                channelListUpdater: channelListUpdater,
                database: database,
                channelWatcherHandler: channelWatcherHandler
            )
        }

        struct Handlers {
            let channelsDidChange: @Sendable @MainActor ([ChatChannel]) async -> Void
        }

        func start(with handlers: Handlers) -> [ChatChannel] {
            channelsDidChange = handlers.channelsDidChange
            do {
                channelListLinker.start(with: eventNotificationCenter)
                return try channelListObserver.startObserving(didChange: handlers.channelsDidChange)
            } catch {
                log.error("Failed to start the channel list observer for query: \(query)")
                return []
            }
        }

        func reload(with newQuery: ChannelListQuery) -> [ChatChannel] {
            query = newQuery
            channelListObserver = Self.makeChannelListObserver(
                for: newQuery,
                database: database,
                clientConfig: clientConfig
            )
            channelListLinker = Self.makeChannelListLinker(
                for: newQuery,
                dynamicFilter: dynamicFilter,
                clientConfig: clientConfig,
                channelListUpdater: channelListUpdater,
                database: database,
                channelWatcherHandler: channelWatcherHandler
            )
            guard let channelsDidChange else { return [] }
            channelListLinker.start(with: eventNotificationCenter)
            do {
                return try channelListObserver.startObserving(didChange: channelsDidChange)
            } catch {
                log.error("Failed to restart the channel list observer after reload for query: \(newQuery)")
                return []
            }
        }

        private static func makeChannelListObserver(
            for query: ChannelListQuery,
            database: DatabaseContainer,
            clientConfig: ChatClientConfig
        ) -> StateLayerDatabaseObserver<ListResult, ChatChannel, ChannelDTO> {
            StateLayerDatabaseObserver(
                database: database,
                fetchRequest: ChannelDTO.channelListFetchRequest(
                    query: query,
                    chatClientConfig: clientConfig
                ),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
                runtimeSorting: query.runtimeSortingValues
            )
        }

        private static func makeChannelListLinker(
            for query: ChannelListQuery,
            dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
            clientConfig: ChatClientConfig,
            channelListUpdater: ChannelListUpdater,
            database: DatabaseContainer,
            channelWatcherHandler: ChannelWatcherHandling
        ) -> ChannelListLinker {
            ChannelListLinker(
                query: query,
                filter: dynamicFilter,
                clientConfig: clientConfig,
                databaseContainer: database,
                worker: channelListUpdater,
                channelWatcherHandler: channelWatcherHandler
            )
        }
    }
}
