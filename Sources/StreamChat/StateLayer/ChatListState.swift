//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of channels matching to the specified query.
@available(iOS 13.0, *)
public final class ChatListState: ObservableObject {
    private let observer: Observer
    private let clientConfig: ChatClientConfig
    let query: ChannelListQuery
    
    init(channels: [ChatChannel], query: ChannelListQuery, clientConfig: ChatClientConfig, database: DatabaseContainer) {
        self.channels = channels
        self.clientConfig = clientConfig
        hasLoadedAllChannels = channels.count < query.pagination.pageSize
        observer = Observer(query: query, chatClientConfig: clientConfig, database: database)
        self.query = query
        
        observer.start(
            with: .init(channelsDidChange: { [weak self] changes in
                guard let self else { return }
                await self.setValue(self.orderedChannels.withListChanges(changes), for: \.channels)
            })
        )
    }
    
    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public private(set) var channels = [ChatChannel]()
    
    /// True, if all the channels were loaded with paginated loading.
    @Published public private(set) var hasLoadedAllChannels = false
    
    // MARK: - Mutating the State
    
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<ChatListState, Value>) -> Value {
        self[keyPath: keyPath]
    }
    
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<ChatListState, Value>) {
        self[keyPath: keyPath] = value
    }
    
    @MainActor var orderedChannels: OrderedChannels {
        OrderedChannels(orderedChannels: channels, query: query, clientConfig: clientConfig)
    }
    
    @MainActor func setSortedChannels(_ sortedChannels: [ChatChannel], hasLoadedAll: Bool) {
        setValue(hasLoadedAll, for: \.hasLoadedAllChannels)
        setValue(sortedChannels, for: \.channels)
    }
}
