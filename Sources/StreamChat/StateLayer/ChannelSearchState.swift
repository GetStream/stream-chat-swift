//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of channel search results.
@MainActor public final class ChannelSearchState: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let observer: Observer

    init(database: DatabaseContainer, clientConfig: ChatClientConfig) {
        observer = Observer(database: database, clientConfig: clientConfig)
        observer.start(
            with: .init(channelsDidChange: { [weak self] in self?.channels = $0 })
        )
        $query
            .assign(to: \.query, on: observer)
            .store(in: &cancellables)
    }

    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public internal(set) var query: ChannelListQuery?

    /// An array of search results for the specified query.
    @Published public internal(set) var channels: [ChatChannel] = []

    // MARK: - Mutating the State

    /// Points the results at the last query the user started.
    func setQuery(_ query: ChannelListQuery?) {
        self.query = query
    }

    /// Stops observing and clears the results.
    func clear() {
        query = nil
        channels = []
    }
}
