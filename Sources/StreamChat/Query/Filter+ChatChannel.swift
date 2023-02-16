//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension Filter where Scope == ChannelListFilterScope {
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

        switch op {
        case .equal, .notEqual, .greater, .greaterOrEqual, .less, .lessOrEqual:
            return comparingPredicate(op)
        case .in, .notIn, .autocomplete, .contains, .exists:
            return collectionPredicate(op)
        case .and, .or, .nor:
            return logicalPredicate(op)
        default:
            log.debug("Unhandled operator \(op) and filterValue \(value)")
            return nil
        }
    }

    private func logicalPredicate(
        _ op: FilterOperator
    ) -> NSPredicate? {
        switch op {
        case .and where value is [Filter<Scope>]:
            guard let filters = value as? [Filter<Scope>] else {
                return nil
            }

            let result = NSCompoundPredicate(
                andPredicateWithSubpredicates: filters.compactMap(\.predicate)
            )
            return result
        case .or where value is [Filter<Scope>]:
            guard let filters = value as? [Filter<Scope>] else {
                return nil
            }
            return NSCompoundPredicate(
                orPredicateWithSubpredicates: filters.compactMap(\.predicate)
            )
        case .nor where value is [Filter<Scope>]:
            guard let filters = value as? [Filter<Scope>] else {
                return nil
            }
            return NSCompoundPredicate(
                notPredicateWithSubpredicate: NSCompoundPredicate(
                    orPredicateWithSubpredicates: filters.compactMap(\.predicate)
                )
            )
        default:
            log.debug("Unhandled operator \(`operator`) and filterValue \(value)")
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
                format: "%@ == %K",
                argumentArray: [value, keyPathString]
            )
        case .notEqual:
            return NSPredicate(
                format: "%@ != %K",
                argumentArray: [value, keyPathString]
            )
        case .greater:
            return NSPredicate(
                format: "%K > %@",
                argumentArray: [keyPathString, value]
            )
        case .greaterOrEqual:
            return NSPredicate(
                format: "%K >= %@",
                argumentArray: [keyPathString, value]
            )
        case .less:
            return NSPredicate(
                format: "%K < %@",
                argumentArray: [keyPathString, value]
            )
        case .lessOrEqual:
            return NSPredicate(
                format: "%K <= %@",
                argumentArray: [keyPathString, value]
            )
        default:
            log.debug("Unhandled operator \(op) and filterValue \(value)")
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
        case .in where value is [FilterValue]:
            guard let filterArray = (value as? [FilterValue]) else {
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

        case .notIn where value is [FilterValue]:
            guard let filterArray = (value as? [FilterValue]) else {
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

        case .autocomplete where value is String:
            guard let prefix = value as? String else {
                return nil
            }
            return NSPredicate(
                format: "%K BEGINSWITH[c] %@",
                argumentArray: [keyPathString, prefix]
            )
        case .contains where value is String:
            guard let needle = value as? String else {
                return nil
            }
            return NSPredicate(
                format: "%K CONTAINS %@",
                argumentArray: [keyPathString, needle]
            )
        case .exists where value is Bool:
            guard let boolValue = value as? Bool else {
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
            log.debug("Unhandled operator \(op) and filterValue \(value)")
            return nil
        }
    }
}
