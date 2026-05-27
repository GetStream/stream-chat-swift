//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of channels matching to the specified query.
@MainActor public final class ChannelListState: ObservableObject {
    private let observer: Observer

    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        channelListUpdater: ChannelListUpdater,
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        channelWatcherHandler: ChannelWatcherHandling
    ) {
        let query = channelListUpdater.loadPredefinedFilter(for: query) ?? query
        self.query = query
        observer = Observer(
            query: query,
            dynamicFilter: dynamicFilter,
            clientConfig: clientConfig,
            channelListUpdater: channelListUpdater,
            database: database,
            eventNotificationCenter: eventNotificationCenter,
            channelWatcherHandler: channelWatcherHandler
        )
        channels = observer.start(
            with: .init(channelsDidChange: { [weak self] in self?.channels = $0 })
        )
    }

    /// The query used for filtering the list of channels.
    public internal(set) var query: ChannelListQuery

    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public internal(set) var channels: [ChatChannel] = []

    func setQuery(_ query: ChannelListQuery) {
        self.query = query
        channels = observer.reload(with: query)
    }
}
