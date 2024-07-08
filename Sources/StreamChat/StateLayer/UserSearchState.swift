//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of user search results.
@MainActor public final class UserSearchState: ObservableObject {
    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public internal(set) var query: UserListQuery?
    
    /// An array of search results for the specified query and pagination state.
    @Published public internal(set) var users = StreamCollection<ChatUser>([])
}

extension UserSearchState {
    /// Updates the query to point to the last query the user started.
    ///
    /// When user is typing and triggers multiple queries, then that last initiated query is used for discarding results from already running queries.
    func setQuery(_ query: UserListQuery) {
        self.query = query
    }
    
    /// Updates the state to include query results if user has not already started a new query.
    ///
    /// * Case 1: User triggered a new search. Then we need to reset the state.
    /// * Case 2: More results are loaded for the same query.
    /// Then we need to merge results while keeping the sort order and handling possible duplicates (example: calling loadNextUsers multiple times).
    func handleDidFetchQuery(
        _ completedQuery: UserListQuery,
        users incomingUsers: [ChatUser]
    ) async {
        if let query = self.query, query.hasFilterOrSortingChanged(completedQuery) {
            // Discard since filter or sorting has changed
            return
        }
        let result: StreamCollection<ChatUser>
        if completedQuery.pagination?.offset == 0 {
            // Reset to the first page
            result = StreamCollection(incomingUsers)
        } else {
            // Filter and sorting are the same but incoming users might contain duplicates (depends how pagination is used)
            let incomingIds = Set(incomingUsers.map(\.id))
            let incomingRemovedUsers = users.filter { !incomingIds.contains($0.id) }
            let sortValues = completedQuery.sort.map(\.sortValue)
            result = StreamCollection((incomingRemovedUsers + incomingUsers).sort(using: sortValues))
        }
        users = result
    }
}

extension UserListQuery {
    func hasFilterOrSortingChanged(_ otherQuery: UserListQuery) -> Bool {
        guard filter?.filterHash == otherQuery.filter?.filterHash else { return true }
        guard sort == otherQuery.sort else { return true }
        return false
    }
}
