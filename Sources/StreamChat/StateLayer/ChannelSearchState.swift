//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of channel search results.
@MainActor public final class ChannelSearchState: ObservableObject {
    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public internal(set) var query: ChannelListQuery?

    /// An array of search results for the specified query.
    @Published public internal(set) var channels: [ChatChannel] = []

    /// The channel list backing the current results, used for pagination.
    var channelList: ChannelList?

    /// `ChannelListQuery` is not `Equatable`, so staleness is decided on its hash.
    private var queryHash: String?
}

extension ChannelSearchState {
    /// Updates the query to point to the last query the user started.
    func setQuery(_ query: ChannelListQuery?) {
        self.query = query
        queryHash = query?.queryHash
    }

    /// Clears the results and the channel list backing them.
    func clear() {
        setQuery(nil)
        channels = []
        channelList = nil
    }

    /// Updates the state with the results of the completed query.
    ///
    /// Results from an outdated query are discarded so the state always
    /// reflects the most recently initiated search.
    func handleDidFetchQuery(
        _ completedQuery: ChannelListQuery,
        channelList: ChannelList,
        channels: [ChatChannel]
    ) {
        guard queryHash == completedQuery.queryHash else { return }
        self.channelList = channelList
        self.channels = channels
    }

    /// Appends a loaded page to the results.
    func handleDidLoadMore(_ completedQuery: ChannelListQuery, channels: [ChatChannel]) {
        guard queryHash == completedQuery.queryHash else { return }
        self.channels = channels
    }
}
