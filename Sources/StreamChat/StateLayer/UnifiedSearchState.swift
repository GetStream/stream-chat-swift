//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents the results of a unified search.
@MainActor public final class UnifiedSearchState: ObservableObject {
    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public internal(set) var query: UnifiedSearchQuery?

    /// The results of the last completed search, with any loaded pages added.
    @Published public internal(set) var results = UnifiedSearchResults()
}

extension UnifiedSearchState {
    func setQuery(_ query: UnifiedSearchQuery) {
        self.query = query
    }

    func clear() {
        query = nil
        results = UnifiedSearchResults()
    }

    func handleDidFetchQuery(_ completedQuery: UnifiedSearchQuery, results: UnifiedSearchResults) {
        guard query == completedQuery else { return }
        self.results = results
    }

    func handleDidFetchNextPage(
        _ page: UnifiedSearchResults,
        loadedFor baseQuery: UnifiedSearchQuery,
        with cursors: [UnifiedSearchEntity: String]
    ) {
        var updatedResults = results
        guard updatedResults.applyNextPage(page, loadedFor: baseQuery, with: cursors) else { return }
        results = updatedResults
    }
}
