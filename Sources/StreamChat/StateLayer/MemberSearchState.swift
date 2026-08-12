//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of channel member search results.
@MainActor public final class MemberSearchState: ObservableObject {
    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public internal(set) var query: ChannelMemberListQuery?

    /// An array of search results for the specified query and pagination state.
    @Published public internal(set) var members: [ChatChannelMember] = []
}

extension MemberSearchState {
    /// Updates the query to point to the last query the user started.
    ///
    /// When user is typing and triggers multiple queries, then that last initiated query is used for discarding results from already running queries.
    func setQuery(_ query: ChannelMemberListQuery) {
        self.query = query
    }

    /// Clears the current query and results.
    func clear() {
        query = nil
        members = []
    }

    /// Updates the state to include query results if user has not already started a new query.
    ///
    /// * Case 1: User triggered a new search. Then we need to reset the state.
    /// * Case 2: More results are loaded for the same query.
    /// Then we need to merge results while handling possible duplicates (example: calling loadMoreMembers multiple times).
    func handleDidFetchQuery(
        _ completedQuery: ChannelMemberListQuery,
        members incomingMembers: [ChatChannelMember]
    ) {
        if let query = self.query, query.hasFilterOrSortingChanged(completedQuery) {
            // Discard since filter or sorting has changed
            return
        }
        if completedQuery.pagination.offset == 0 {
            // Reset to the first page
            members = incomingMembers
        } else {
            // Filter and sorting are the same but incoming members might contain duplicates
            let incomingIds = Set(incomingMembers.map(\.id))
            let existingWithoutIncoming = members.filter { !incomingIds.contains($0.id) }
            members = existingWithoutIncoming + incomingMembers
        }
    }
}

extension ChannelMemberListQuery {
    func hasFilterOrSortingChanged(_ otherQuery: ChannelMemberListQuery) -> Bool {
        guard cid == otherQuery.cid else { return true }
        guard filter?.filterHash == otherQuery.filter?.filterHash else { return true }
        guard sort == otherQuery.sort else { return true }
        return false
    }
}
