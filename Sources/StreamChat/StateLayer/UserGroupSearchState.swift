//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of user group search results.
@MainActor public final class UserGroupSearchState: ObservableObject {
    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public internal(set) var query: UserGroupSearchQuery?

    /// An array of search results for the specified query.
    @Published public internal(set) var userGroups: [UserGroup] = []
}

extension UserGroupSearchState {
    /// Updates the query to point to the last query the user started.
    func setQuery(_ query: UserGroupSearchQuery) {
        self.query = query
    }

    /// Updates the state with the results of the completed query.
    ///
    /// Results from an outdated query are discarded so the state always
    /// reflects the most recently initiated search.
    func handleDidFetchQuery(_ completedQuery: UserGroupSearchQuery, userGroups: [UserGroup]) {
        guard query == completedQuery else { return }
        self.userGroups = userGroups
    }
}
