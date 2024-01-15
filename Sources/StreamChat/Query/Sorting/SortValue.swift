//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct SortValue<T> {
    let keyPath: PartialKeyPath<T>
    let isAscending: Bool
}

extension Array {
    func sort(using sorting: [SortValue<Element>]) -> [Element] {
        var result = self

        for sort in sorting.reversed() {
            result = result.sorted { lhs, rhs in
                let lhsValue = lhs[keyPath: sort.keyPath]
                let rhsValue = rhs[keyPath: sort.keyPath]

                if sort.isAscending, evaluate(lhs: lhsValue, rhs: rhsValue, isAscending: sort.isAscending) {
                    return true
                } else if !sort.isAscending, evaluate(lhs: lhsValue, rhs: rhsValue, isAscending: sort.isAscending) {
                    return true
                } else {
                    return false
                }
            }
        }

        return result
    }

    private func evaluate(lhs: Any?, rhs: Any?, isAscending: Bool) -> Bool {
        if lhs == nil, rhs != nil, !isAscending {
            return true
        } else if lhs != nil, rhs == nil, isAscending {
            return true
        }

        if let lString = lhs as? String, let rString = rhs as? String {
            return isAscending ? lString < rString : lString > rString
        } else if let lInt = lhs as? Int, let rInt = rhs as? Int {
            return isAscending ? lInt < rInt : lInt > rInt
        } else if let lDouble = lhs as? Double, let rDouble = rhs as? Double {
            return isAscending ? lDouble < rDouble : lDouble > rDouble
        } else if let lDate = lhs as? Date, let rDate = rhs as? Date {
            return isAscending ? lDate < rDate : lDate > rDate
        } else if let lBool = lhs as? Bool, let rBool = rhs as? Bool {
            // The logic is actually the other way around, and this a backend issue.
            // But we can't change the backend at the moment otherwise it would be a breaking change.
            // So for now, isAscending means true values will come first, and then false.
            return isAscending ? lBool && !rBool : !lBool && rBool
        }

        return false
    }
}
