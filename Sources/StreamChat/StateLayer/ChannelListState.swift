//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of channels matching to the specified query.
@MainActor public final class ChannelListState: ObservableObject {
    private var observer: Observer
    private var shouldSkipInitialRemoteUpdate = false
    private var handlers: Observer.Handlers {
        .init(channelsDidChange: { [weak self] in self?.channels = $0 })
    }
    
    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        channelListUpdater: ChannelListUpdater,
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        channelWatcherHandler: ChannelWatcherHandling
    ) {
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
        channels = observer.start(with: handlers)
    }
    
    /// The query used for filtering the list of channels.
    public private(set) var query: ChannelListQuery
    
    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public internal(set) var channels: [ChatChannel] = []

    func skipNextInitialRemoteUpdate() {
        shouldSkipInitialRemoteUpdate = true
    }

    func consumeShouldSkipInitialRemoteUpdate() -> Bool {
        defer { shouldSkipInitialRemoteUpdate = false }
        return shouldSkipInitialRemoteUpdate
    }

    func reset(
        query: ChannelListQuery,
        minimumFetchLimit: Int
    ) {
        self.query = query
        channels = observer.resetFetchRequest(query: query, minimumFetchLimit: minimumFetchLimit)
    }
}
