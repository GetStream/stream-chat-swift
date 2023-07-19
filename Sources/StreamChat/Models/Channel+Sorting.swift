//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct SortValue<T> {
    let keyPath: PartialKeyPath<T>
    let isAscending: Bool
}

extension Array {
    func sortWithKeyPath(with sorting: [SortValue<Element>]) -> [Element] {
        func evaluate(lhs: Any?, rhs: Any?, isAscending: Bool) -> Bool {
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
            }

            return false
        }

        return sorted { lhs, rhs in
            for sort in sorting {
                let lhsValue = lhs[keyPath: sort.keyPath]
                let rhsValue = rhs[keyPath: sort.keyPath]

                if sort.isAscending, evaluate(lhs: lhsValue, rhs: rhsValue, isAscending: sort.isAscending) {
                    return true
                } else if !sort.isAscending, evaluate(lhs: lhsValue, rhs: rhsValue, isAscending: sort.isAscending) {
                    return true
                } else {
                    continue
                }
            }

            return false
        }
    }
}

private extension RawJSON {
    var sortValue: String? {
        if let number = numberValue {
            return number.sortValue
        } else if let string = stringValue {
            return string
        } else {
            return nil
        }
    }
}

private extension Int {
    var sortValue: String { "\(self)" }
}

private extension Double {
    var sortValue: String { "\(self)" }
}

private extension Date {
    var sortValue: String { description }
}
