//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum SearchQueryLength {
    /// Infers a search query length from a filter tree for debounce policy selection.
    ///
    /// Uses the longest string value found under `$autocomplete` / `$query` operators.
    /// Falls back to `3` (standard debounce bucket) when no search text is present.
    static func fromFilter<Scope: FilterScope>(_ filter: Filter<Scope>?) -> Int {
        guard let filter else { return 3 }
        if let length = longestSearchTextLength(in: filter) {
            return length
        }
        return 3
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
