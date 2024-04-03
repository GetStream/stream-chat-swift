//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of channels matching to the specified query.
@available(iOS 13.0, *)
public final class ChannelListState: ObservableObject {
    private let observer: Observer
    let query: ChannelListQuery
    
    init(
        initialChannels: [ChatChannel]?,
        query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        channelListUpdater: ChannelListUpdater,
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter
    ) {
        channels = StreamCollection<ChatChannel>(initialChannels ?? [])
        self.query = query
        observer = Observer(
            query: query,
            dynamicFilter: dynamicFilter,
            clientConfig: clientConfig,
            channelListUpdater: channelListUpdater,
            database: database,
            eventNotificationCenter: eventNotificationCenter
        )
        observer.start(
            with: .init(channelsDidChange: { [weak self] channels, changes in
                await self?.noteChannelsDidChange(channels, changes)
            })
        )
        if initialChannels == nil {
            channels = observer.channelListObserver.currentItems()
        }
    }
    
    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public private(set) var channels = StreamCollection<ChatChannel>([])
    
    /// An array of latest channel list changes.
    ///
    /// - Note: The ``channelListChanges`` property is updated just before ``channels`` property changes.
    public private(set) var channelListChanges: [ListChange<ChannelId>] = []
    
    // MARK: - Mutating the State
    
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<ChannelListState, Value>) -> Value {
        self[keyPath: keyPath]
    }
    
    @MainActor private func noteChannelsDidChange(_ channels: StreamCollection<ChatChannel>, _ changes: [ListChange<ChannelId>]) {
        channelListChanges = changes
        self.channels = channels
    }
}
