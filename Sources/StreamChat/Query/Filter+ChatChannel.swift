//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Filter where Scope == ChannelListFilterScope {
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

    /// If it can be translated, this will return
    /// an NSPredicate instance that is equivalent
    /// to the current filter.
    ///
    /// For now it's limited to ChannelList as it's not
    /// needed anywhere else
    ///
    /// The predicate will be automatically be used
    /// by the ChannelDTO to create the
    /// fetchRequest.
    ///
    /// - Important:
    /// The behaviour of the ChannelDTO, to include or not
    /// the predicate in the fetchRequest, it's controlled by
    /// `ChatClientConfig.isChannelAutomaticFilteringEnabled`
    var predicate: NSPredicate? {
        guard let op = FilterOperator(rawValue: `operator`) else {
            return nil
        }

        if let overridePredicate = predicateMapper?(op, mappedValue) {
            return overridePredicate
        }

        switch op {
        case .equal, .notEqual, .greater, .greaterOrEqual, .less, .lessOrEqual:
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
            guard let filters = mappedValue as? [Filter<Scope>] else {
                return nil
            }

            let result = NSCompoundPredicate(
                andPredicateWithSubpredicates: filters.compactMap(\.predicate)
            )
            return result
        case .or where mappedValue is [Filter<Scope>]:
            guard let filters = mappedValue as? [Filter<Scope>] else {
                return nil
            }
            return NSCompoundPredicate(
                orPredicateWithSubpredicates: filters.compactMap(\.predicate)
            )
        case .nor where mappedValue is [Filter<Scope>]:
            guard let filters = mappedValue as? [Filter<Scope>] else {
                return nil
            }
            return NSCompoundPredicate(
                notPredicateWithSubpredicate: NSCompoundPredicate(
                    orPredicateWithSubpredicates: filters.compactMap(\.predicate)
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
}

extension String {
    fileprivate func prepend(_ prefixToPrepend: String, ifCondition: Bool) -> String {
        guard ifCondition else { return self }
        return "\(prefixToPrepend)\(self)"
    }
}
