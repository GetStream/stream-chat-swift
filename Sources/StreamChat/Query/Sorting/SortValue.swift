//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct SortValue<T> {
    let keyPath: PartialKeyPath<T>
    let isAscending: Bool
}

extension Array {
    /// Returns the elements of the sequence, sorted using the given sort values as the comparison between elements.
    ///
    /// The first `SortValue` is the primary key and subsequent `SortValue`s are for breaking the tie.
    func sorted(using sortValues: [SortValue<Element>]) -> [Element] {
        guard !sortValues.isEmpty else { return self }
        return sorted { lhs, rhs in
            for sortValue in sortValues {
                let lhsValue = lhs[keyPath: sortValue.keyPath]
                let rhsValue = rhs[keyPath: sortValue.keyPath]
                let isAscending = sortValue.isAscending
                // These are type-erased, therefore we need to manually cast them
                if let result = nilComparison(lhs: lhsValue, rhs: rhsValue, isAscending: isAscending) {
                    return result
                } else if let result = areInIncreasingOrder(lhs: lhsValue, rhs: rhsValue, type: Date.self, isAscending: isAscending) {
                    return result
                } else if let result = areInIncreasingOrder(lhs: lhsValue, rhs: rhsValue, type: String.self, isAscending: isAscending) {
                    return result
                } else if let result = areInIncreasingOrder(lhs: lhsValue, rhs: rhsValue, type: Int.self, isAscending: isAscending) {
                    return result
                } else if let result = areInIncreasingOrder(lhs: lhsValue, rhs: rhsValue, type: Double.self, isAscending: isAscending) {
                    return result
                } else if let lBool = lhsValue as? Bool, let rBool = rhsValue as? Bool, lBool != rBool {
                    // Backend considers boolean sorting in reversed order.
                    return isAscending ? lBool && !rBool : !lBool && rBool
                }
            }
            return false
        }
    }
    
    /// Dedicated nil handling for Any type which returns false if we do `lhs == nil`.
    private func nilComparison(lhs: Any, rhs: Any, isAscending: Bool) -> Bool? {
        func isAnyNil(_ value: Any) -> Bool {
            if case Optional<Any>.none = value {
                return true
            } else {
                return false
            }
        }
        switch (isAnyNil(lhs), isAnyNil(rhs)) {
        case (true, true): return nil
        case (true, false): return isAscending
        case (false, true): return !isAscending
        case (false, false): return nil
        }
    }
    
    /// Nil, if type mismatch or typed values are equal and we need to consider the next sorting key instead.
    private func areInIncreasingOrder<T>(lhs: Any, rhs: Any, type: T.Type, isAscending: Bool) -> Bool? where T: Comparable {
        guard let lhs = lhs as? T, let rhs = rhs as? T else { return nil }
        guard lhs != rhs else { return nil }
        return isAscending ? lhs < rhs : lhs > rhs
    }
}
