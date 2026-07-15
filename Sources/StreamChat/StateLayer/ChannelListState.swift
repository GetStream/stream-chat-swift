//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of channels matching to the specified query.
@MainActor public final class ChannelListState: ObservableObject {
    private let observer: Observer
    private var handlers: Observer.Handlers {
        .init(channelsDidChange: { [weak self] channels, changes in
            guard let self else { return }
            self.channels = channels
            self.channelsDidChangeHandler?(changes)
        })
    }

    init(query: ChannelListQuery, observer: Observer) {
        self.query = query
        self.observer = observer
        channels = observer.start(with: handlers)
    }

    /// The query used for filtering the list of channels.
    public internal(set) var query: ChannelListQuery

    /// A Boolean value that returns whether pagination is finished.
    var hasLoadedAllPreviousChannels = false

    /// An array of channels for the specified ``ChannelListQuery``.
    @Published public internal(set) var channels: [ChatChannel] = []

    var channelsDidChangeHandler: (@MainActor ([ListChange<ChatChannel>]) -> Void)? {
        didSet {
            guard let channelsDidChangeHandler else { return }
            channelsDidChangeHandler(channels.enumerated().map { .insert($1, index: IndexPath(item: $0, section: 0)) })
        }
    }

    func setQuery(_ query: ChannelListQuery) {
        self.query = query
        channels = observer.reload(with: query)
    }
}
