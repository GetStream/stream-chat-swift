//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13.0, *)
extension ChannelListState {
    final class Observer {
        private let channelListObserver: BackgroundListDatabaseObserver<ChatChannel, ChannelDTO>
        private let query: ChannelListQuery
        private var syncRepositoryCancellable: AnyCancellable?
        
        init(query: ChannelListQuery, chatClientConfig: ChatClientConfig, database: DatabaseContainer) {
            self.query = query
            // Note that for channel list we sort outside of NSFetchRequest because ChannelListQuery defines its own sorting (see runtimeSorting)
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
            let channelsDidChange: (StreamCollection<ChatChannel>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            syncRepositoryCancellable = NotificationCenter.default
                .publisher(for: SyncRepository.syncRepositoryChannelListQueryRegistrationNotification)
                .compactMap { $0.object as? SyncRepository.ChannelListRegistry }
                .sink(receiveValue: { [query] registry in registry.register(query: query) })
            
            channelListObserver.onDidChange = { [weak channelListObserver] _ in
                guard let items = channelListObserver?.items else { return }
                let collection = StreamCollection(items)
                Task { await handlers.channelsDidChange(collection) }
            }
            
            do {
                try channelListObserver.startObserving()
            } catch {
                log.error("Failed to start the channel list observer for query: \(query)")
            }
        }
    }
}
