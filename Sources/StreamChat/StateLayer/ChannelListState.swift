//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of channels matching to the specified query.
@available(iOS 13.0, *)
@MainActor public final class ChannelListState: ObservableObject {
    private let observer: Observer
    private let query: ChannelListQuery
    
    init(
        initialChannels: [ChatChannel],
        query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        channelListUpdater: ChannelListUpdater,
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter
    ) {
        self.query = query
        channels = StreamCollection<ChatChannel>(initialChannels)
        observer = Observer(
            query: query,
            dynamicFilter: dynamicFilter,
            clientConfig: clientConfig,
            channelListUpdater: channelListUpdater,
            database: database,
            eventNotificationCenter: eventNotificationCenter
        )
        observer.start(
            with: .init(channelsDidChange: { [weak self] in self?.channels = $0 })
        )
        if initialChannels.isEmpty {
            channels = observer.channelListObserver.items
        }
    }
    
    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public internal(set) var channels = StreamCollection<ChatChannel>([])
}
