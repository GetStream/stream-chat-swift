//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension Filter {
    var predicate: NSPredicate? {
        guard let op = FilterOperator(rawValue: self.operator) else { return nil }
        let dtoKey = autoKey?.dtoKey

        let makeComparablePredicate: (_ compareToken: String) -> NSPredicate? = { compareToken in
            guard let key = dtoKey else { return nil }
            let value: CVarArg = autoKey?.value ?? value.description
            return NSPredicate(format: "\(key) \(compareToken) %@", value)
        }

        let makeCompoundPredicate: (_ logicalType: NSCompoundPredicate.LogicalType) -> NSCompoundPredicate? = { logicalType in
            guard let value = self.value as? [Filter] else { return nil }
            let predicates = value.compactMap(\.predicate)
            guard !predicates.isEmpty else { return nil }
            return NSCompoundPredicate(type: logicalType, subpredicates: predicates)
        }

        switch op {
        case .equal:
            return makeComparablePredicate("==")
        case .notEqual:
            return makeComparablePredicate("!=")
        case .greater:
            return makeComparablePredicate(">")
        case .greaterOrEqual:
            return makeComparablePredicate(">=")
        case .less:
            return makeComparablePredicate("<")
        case .lessOrEqual:
            return makeComparablePredicate("<=")
        case .in:
            guard let key = dtoKey else { return nil }
            guard let valueArray = value as? [CVarArg] else { return nil }
            return NSCompoundPredicate(
                type: .and,
                subpredicates: valueArray.map {
                    NSPredicate(format: "ANY \(key) == %@", $0)
                }
            )
        case .notIn:
            guard let key = dtoKey else { return nil }
            guard let valueArray = value as? NSArray else { return nil }
            return NSCompoundPredicate(format: "NONE \(key) IN %@", valueArray)
        case .contains:
            guard let key = dtoKey else { return nil }
            guard let valueArray = value as? [CVarArg] else { return nil }
            return NSPredicate(format: "\(key) IN %@", valueArray)
        case .exists:
            guard let key = dtoKey else { return nil }
            guard let booleanValue = value as? Bool else { return nil }
            let compareToken = booleanValue == true ? "!=" : "=="
            return NSPredicate(format: "\(key) \(compareToken) nil")
        case .and:
            return makeCompoundPredicate(.and)
        case .or:
            return makeCompoundPredicate(.or)
        case .nor:
            return makeCompoundPredicate(.not)
        case .autocomplete:
            return nil
        case .query:
            return nil
        }
    }
}
