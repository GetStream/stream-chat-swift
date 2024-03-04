//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ChatListState {
    struct Observer {
        private let channelListObserver: BackgroundListDatabaseObserver<ChatChannel, ChannelDTO>
        private let query: ChannelListQuery
        
        init(query: ChannelListQuery, chatClientConfig: ChatClientConfig, database: DatabaseContainer) {
            self.query = query
            channelListObserver = BackgroundListDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: ChannelDTO.channelListFetchRequest(
                    query: query,
                    chatClientConfig: chatClientConfig
                ),
                itemCreator: {
                    try $0.asModel() as ChatChannel
                },
                sorting: query.sort.runtimeSorting
            )
        }
        
        struct Handlers {
            let channelsDidChange: ([ListChange<ChatChannel>]) async -> Void
        }
        
        func start(with handlers: Handlers) {
            channelListObserver.onDidChange = { changes in Task { await handlers.channelsDidChange(changes) } }
            
            do {
                try channelListObserver.startObserving()
            } catch {
                log.error("Failed to start the channel list observer for query: \(query)")
            }
        }
    }
}
