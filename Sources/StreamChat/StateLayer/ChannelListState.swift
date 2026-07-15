//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A non-isolated, queue-backed observable state for a list of channels.
///
/// Reads of ``channels`` and delivery of changes are serialized on the same `queue`,
/// which makes it safe to use from non-isolated contexts (like ``ChatChannelListController``)
/// without a main-actor requirement and without blocking on the database queue.
public class ChannelListObservableState: ObservableObject, @unchecked Sendable {
    private let observer: ChannelListState.Observer
    /// The queue used for reading and mutating the state as well as for delivering changes.
    let queue: DispatchQueue

    private var handlers: ChannelListState.Observer.Handlers {
        .init(channelsDidChange: { [weak self] channels, changes in
            self?.channels = channels
            self?.latestChanges = changes
        })
    }

    init(
        queue: DispatchQueue,
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
        self.queue = queue
        observer = ChannelListState.Observer(
            query: query,
            dynamicFilter: dynamicFilter,
            clientConfig: clientConfig,
            channelListUpdater: channelListUpdater,
            database: database,
            eventNotificationCenter: eventNotificationCenter,
            channelWatcherHandler: channelWatcherHandler
        )
        channels = observer.start(on: queue, with: handlers)
    }

    /// The query used for filtering the list of channels.
    public internal(set) var query: ChannelListQuery

    /// A Boolean value that returns whether pagination is finished.
    var hasLoadedAllPreviousChannels = false

    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public internal(set) var channels: [ChatChannel] = []

    /// The most recent list changes applied to ``channels``.
    ///
    /// - Note: Published after ``channels`` has been updated, which allows delegate-style
    ///   consumers (e.g. ``ChatChannelListController``) to read the updated list when reacting to changes.
    @Published private(set) var latestChanges = [ListChange<ChatChannel>]()

    /// Reloads the observer for a new query.
    ///
    /// The query and channels are updated on ``queue`` so that ``channels`` mutations stay on the
    /// same executor that delivers observer changes.
    func setQuery(_ query: ChannelListQuery) {
        queue.async { [weak self] in
            guard let self else { return }
            self.query = query
            self.channels = self.observer.reload(with: query)
        }
    }
}

/// Represents a list of channels matching to the specified query.
///
/// - Note: The state is delivered and read on the main actor. For a non-isolated variant used by
///   controllers, see ``ChannelListObservableState``.
@MainActor public final class ChannelListState: ChannelListObservableState {
    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        channelListUpdater: ChannelListUpdater,
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        channelWatcherHandler: ChannelWatcherHandling
    ) {
        super.init(
            queue: .main,
            query: query,
            dynamicFilter: dynamicFilter,
            clientConfig: clientConfig,
            channelListUpdater: channelListUpdater,
            database: database,
            eventNotificationCenter: eventNotificationCenter,
            channelWatcherHandler: channelWatcherHandler
        )
    }
}
