//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension Filter {
    var predicate: NSPredicate? {
        guard let op = FilterOperator(rawValue: self.operator) else { return nil }

        let unableToResolve: () -> NSPredicate? = {
            let message = ""
            log.assertionFailure(message)
            return nil
        }

        let dtoKey = autoKey?.dtoKey ?? key

        let makeComparablePredicate: (_ compareToken: String) -> NSPredicate? = { compareToken in
            guard let key = dtoKey else { return unableToResolve() }
            let valueToUse: CVarArg = autoKey?.value ?? value.description
            return NSPredicate(format: "\(key) \(compareToken) %@", valueToUse)
        }

        let makeCompoundPredicate: (_ logicalType: NSCompoundPredicate.LogicalType) -> NSPredicate? = { logicalType in
            guard let value = self.value as? [Filter] else { return unableToResolve() }
            let predicates = value.compactMap(\.predicate)
            guard !predicates.isEmpty else { return unableToResolve() }
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
            guard let key = dtoKey else { return unableToResolve() }
            guard let valueArray = value as? [FilterValue] else { return unableToResolve() }
            return NSCompoundPredicate(
                type: .and,
                subpredicates: valueArray.map {
                    NSPredicate(format: "ANY \(key) == %@", $0.description)
                }
            )
        case .notIn:
            guard let key = dtoKey else { return unableToResolve() }
            guard let valueArray = value as? NSArray else { return unableToResolve() }
            return NSCompoundPredicate(format: "NONE \(key) IN %@", valueArray)
        case .contains:
            return makeComparablePredicate("IN")
        case .exists:
            guard let key = dtoKey else { return unableToResolve() }
            guard let booleanValue = value as? Bool else { return unableToResolve() }
            let compareToken = booleanValue == true ? "!=" : "=="
            return NSPredicate(format: "\(key) \(compareToken) nil")
        case .and:
            return makeCompoundPredicate(.and)
        case .or:
            return makeCompoundPredicate(.or)
        case .nor:
            guard let value = self.value as? [Filter] else { return unableToResolve() }
            let predicates = value.compactMap {
                $0.predicate.map(NSCompoundPredicate.init(notPredicateWithSubpredicate:))
            }
            guard !predicates.isEmpty else { return unableToResolve() }
            return NSCompoundPredicate(type: .and, subpredicates: predicates)
        case .query:
            guard let key = dtoKey else { return unableToResolve() }
            let valueToUse: CVarArg = autoKey?.value ?? value.description
            return NSPredicate(format: "\(key) CONTAINS %@", valueToUse)
        case .autocomplete:
            return unableToResolve()
        }
    }
}
