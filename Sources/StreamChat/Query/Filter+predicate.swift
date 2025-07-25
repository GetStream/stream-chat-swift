//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Filter {
    /// Converts the current filter into an NSPredicate if it can be translated.
    ///
    /// This is useful to make sure the backend filters can be used to filter data in CoreData.
    ///
    /// **Note:** Extra data properties will be ignored since they are stored in binary format.
    var predicate: NSPredicate? {
        guard let op = FilterOperator(rawValue: `operator`) else {
            return nil
        }

        if let overridePredicate = predicateMapper?(op, mappedValue) {
            return overridePredicate
        }

        switch op {
        case .equal:
            if mappedValue is [FilterValue] {
                return collectionPredicate(op)
            } else {
                return comparingPredicate(op)
            }
        case .notEqual, .greater, .greaterOrEqual, .less, .lessOrEqual:
            return comparingPredicate(op)
        case .in, .notIn, .autocomplete, .contains, .exists:
            return collectionPredicate(op)
        case .and, .or, .nor:
            return logicalPredicate(op)
        default:
            log.debug("Unhandled operator \(op) and filterValue \(mappedValue)")
            return nil
        }
    }

    private func logicalPredicate(
        _ op: FilterOperator
    ) -> NSPredicate? {
        switch op {
        case .and where mappedValue is [Filter<Scope>]:
            guard let predicates = (mappedValue as? [Filter<Scope>])?.compactMap(\.predicate), !predicates.isEmpty else {
                return nil
            }

            let result = NSCompoundPredicate(
                andPredicateWithSubpredicates: predicates
            )
            return result
        case .or where mappedValue is [Filter<Scope>]:
            guard let predicates = (mappedValue as? [Filter<Scope>])?.compactMap(\.predicate), !predicates.isEmpty else {
                return nil
            }
            return NSCompoundPredicate(
                orPredicateWithSubpredicates: predicates
            )
        case .nor where mappedValue is [Filter<Scope>]:
            guard let predicates = (mappedValue as? [Filter<Scope>])?.compactMap(\.predicate), !predicates.isEmpty else {
                return nil
            }
            return NSCompoundPredicate(
                notPredicateWithSubpredicate: NSCompoundPredicate(
                    orPredicateWithSubpredicates: predicates
                )
            )
        default:
            log.debug("Unhandled operator \(`operator`) and filterValue \(mappedValue)")
            return nil
        }
    }

    private func comparingPredicate(
        _ op: FilterOperator
    ) -> NSPredicate? {
        guard key != nil, let keyPathString = keyPathString else {
            return nil
        }

        switch op {
        case .equal:
            return NSPredicate(
                format: "%K == %@",
                argumentArray: [keyPathString, mappedValue]
            )
        case .notEqual:
            return NSPredicate(
                format: "%K != %@",
                argumentArray: [keyPathString, mappedValue]
            )
        case .greater:
            return NSPredicate(
                format: "%K > %@",
                argumentArray: [keyPathString, mappedValue]
            )
        case .greaterOrEqual:
            return NSPredicate(
                format: "%K >= %@",
                argumentArray: [keyPathString, mappedValue]
            )
        case .less:
            return NSPredicate(
                format: "%K < %@",
                argumentArray: [keyPathString, mappedValue]
            )
        case .lessOrEqual:
            return NSPredicate(
                format: "%K <= %@",
                argumentArray: [keyPathString, mappedValue]
            )
        default:
            log.debug("Unhandled operator \(op) and filterValue \(mappedValue)")
            return nil
        }
    }

    private func collectionPredicate(
        _ op: FilterOperator
    ) -> NSPredicate? {
        guard key != nil, let keyPathString = keyPathString
        else {
            return nil
        }

        switch op {
        case .in where mappedValue is [FilterValue]:
            guard let filterArray = mappedArrayValue else {
                return nil
            }
            return NSCompoundPredicate(
                orPredicateWithSubpredicates: filterArray.map { subValue in
                    NSPredicate(
                        format: "%@ IN %K",
                        argumentArray: [subValue, keyPathString]
                    )
                }
            )

        case .equal where mappedValue is [FilterValue]:
            guard let filterArray = mappedArrayValue else {
                return nil
            }
            return NSCompoundPredicate(
                andPredicateWithSubpredicates: filterArray.map { subValue in
                    NSPredicate(
                        format: "%@ IN %K",
                        argumentArray: [subValue, keyPathString]
                    )
                }
            )
            
        case .notIn where mappedValue is [FilterValue]:
            guard let filterArray = mappedArrayValue else {
                return nil
            }
            return NSCompoundPredicate(
                notPredicateWithSubpredicate: NSCompoundPredicate(
                    andPredicateWithSubpredicates: filterArray.map { subValue in
                        NSPredicate(
                            format: "%@ IN %K",
                            argumentArray: [subValue, keyPathString]
                        )
                    }
                )
            )

        case .autocomplete where mappedValue is String:
            guard let prefix = mappedValue as? String else {
                return nil
            }
            return NSPredicate(
                format: "%K CONTAINS[c] %@".prepend(("ANY "), ifCondition: isCollectionFilter),
                argumentArray: [keyPathString, prefix]
            )
        case .contains where mappedValue is String:
            guard let needle = mappedValue as? String else {
                return nil
            }
            return NSPredicate(
                format: "%K CONTAINS %@".prepend(("ANY "), ifCondition: isCollectionFilter),
                argumentArray: [keyPathString, needle]
            )
        case .exists where mappedValue is Bool:
            guard let boolValue = mappedValue as? Bool else {
                return nil
            }
            if boolValue {
                return NSPredicate(
                    format: "%K != nil",
                    argumentArray: [keyPathString]
                )
            } else {
                return NSPredicate(
                    format: "%K == nil",
                    argumentArray: [keyPathString]
                )
            }
        default:
            log.debug("Unhandled operator \(op) and filterValue \(mappedValue)")
            return nil
        }
    }

    /// If a valueMapper was provided, then here we will try to transform the value
    /// using the mapper.
    ///
    /// If the mapper returns nil, the original value will be returned
    var mappedValue: FilterValue {
        valueMapper?(value) ?? value
    }

    /// If the mappedValues is an array of FilterValues, we will try to transform them using the valueMapper
    /// to ensure that both parts of the comparison are of the same type.
    ///
    /// If the value is not an array, this value will return nil.
    /// If the valueMapper isn't provided or the value mapper returns nil, the original value will be included
    /// in the array.
    var mappedArrayValue: [FilterValue]? {
        guard let filterArray = mappedValue as? [FilterValue] else {
            return nil
        }
        return filterArray.map { valueMapper?($0) ?? $0 }
    }
}

extension String {
    fileprivate func prepend(_ prefixToPrepend: String, ifCondition: Bool) -> String {
        guard ifCondition else { return self }
        return "\(prefixToPrepend)\(self)"
    }
}
