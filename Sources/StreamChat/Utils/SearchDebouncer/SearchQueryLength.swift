//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum SearchQueryLength {
    /// Returns the length of the search text in a filter tree, or `nil` when it holds none.
    ///
    /// Only the text-search operators (`$autocomplete`, `$q`) count. Those are the ones a user
    /// types into incrementally, so a query built around them is debounced on the length found
    /// here even when it is combined with other filters.
    ///
    /// Everything else returns `nil`, meaning "not a text search, do not debounce". Exact
    /// matches are deliberately excluded: `.equal` on a string field is a lookup by a known
    /// value (a cid, an id), not incremental typing, and delaying those would be a regression.
    static func fromFilter<Scope: FilterScope>(_ filter: Filter<Scope>?) -> Int? {
        guard let filter else { return nil }
        return longestSearchTextLength(in: filter)
    }

    private static func longestSearchTextLength<Scope: FilterScope>(in filter: Filter<Scope>) -> Int? {
        let isTextSearchOperator = filter.operator == FilterOperator.autocomplete.rawValue
            || filter.operator == FilterOperator.query.rawValue
        if isTextSearchOperator, let text = filter.value as? String {
            return text.count
        }

        if let nested = filter.value as? [Filter<Scope>] {
            return nested.compactMap { longestSearchTextLength(in: $0) }.max()
        }

        return nil
    }
}
