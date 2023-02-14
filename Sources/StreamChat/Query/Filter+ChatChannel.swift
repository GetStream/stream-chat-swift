//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatChannel {
    func meets(_ filter: Filter<ChannelListFilterScope>) throws -> Bool {
        // This is a work in progress.
        // The idea is that in a further iteration we provide a runtime evaluation of the filter to determine
        // if the channel matches the filter. This is a costly operation, and it is recommended to avoid it.
        // The recommended approach is to pass a `filter` block when initializing a `ChatChannelListController`
        true
    }
}

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
    /// `StreamRuntimeCheck.isChannelLocalFilteringEnabled`
    var predicate: NSPredicate? {
        guard let `operator` = FilterOperator(rawValue: `operator`) else {
            return nil
        }

        switch `operator` {
        case .equal, .notEqual, .greater, .greaterOrEqual, .less, .lessOrEqual:
            return comparingPredicate(`operator`)
        case .in, .notIn, .autocomplete, .contains, .exists:
            return collectionPredicate(`operator`)
        case .and, .or, .nor:
            return logicalPredicate(`operator`)
        default:
            log.debug("Unhandled operator \(`operator`) and filterValue \(value)")
            return nil
        }
    }

    private func logicalPredicate(
        _ operator: FilterOperator
    ) -> NSPredicate? {
        switch `operator` {
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
        _ operator: FilterOperator
    ) -> NSPredicate? {
        guard key != nil, let keyPathValueProvider = keyPathValueProvider else {
            return nil
        }

        switch `operator` {
        case .equal:
            return NSPredicate(
                format: "%@ == %K",
                argumentArray: [value, keyPathValueProvider()]
            )
        case .notEqual:
            return NSPredicate(
                format: "%@ != %K",
                argumentArray: [value, keyPathValueProvider()]
            )
        case .greater:
            return NSPredicate(
                format: "%K > %@",
                argumentArray: [keyPathValueProvider(), value]
            )
        case .greaterOrEqual:
            return NSPredicate(
                format: "%K >= %@",
                argumentArray: [keyPathValueProvider(), value]
            )
        case .less:
            return NSPredicate(
                format: "%K < %@",
                argumentArray: [keyPathValueProvider(), value]
            )
        case .lessOrEqual:
            return NSPredicate(
                format: "%K <= %@",
                argumentArray: [keyPathValueProvider(), value]
            )
        default:
            log.debug("Unhandled operator \(`operator`) and filterValue \(value)")
            return nil
        }
    }

    private func collectionPredicate(
        _ operator: FilterOperator
    ) -> NSPredicate? {
        guard key != nil, let keyPathValueProvider = keyPathValueProvider
        else {
            return nil
        }

        switch `operator` {
        case .in where value is [FilterValue]:
            guard let filterArray = (value as? [FilterValue]) else {
                return nil
            }
            return NSCompoundPredicate(
                andPredicateWithSubpredicates: filterArray.map { subValue in
                    NSPredicate(
                        format: "%@ IN %K",
                        argumentArray: [subValue, keyPathValueProvider()]
                    )
                }
            )

        case .notIn where value is [FilterValue]:
            guard let filterArray = (value as? [FilterValue]) else {
                return nil
            }
            return NSCompoundPredicate(
                andPredicateWithSubpredicates: filterArray.map { subValue in
                    NSPredicate(
                        format: "NOT(%@ IN %K)",
                        argumentArray: [subValue, keyPathValueProvider()]
                    )
                }
            )

        case .autocomplete where value is String:
            guard let prefix = value as? String else {
                return nil
            }
            return NSPredicate(
                format: "%K BEGINSWITH[c] %@",
                argumentArray: [keyPathValueProvider(), prefix]
            )
        case .contains where value is String:
            guard let needle = value as? String else {
                return nil
            }
            return NSPredicate(
                format: "%K CONTAINS %@",
                argumentArray: [keyPathValueProvider(), needle]
            )
        case .exists where value is Bool:
            guard let boolValue = value as? Bool else {
                return nil
            }
            if boolValue {
                return NSPredicate(
                    format: "%K != nil",
                    argumentArray: [keyPathValueProvider()]
                )
            } else {
                return NSPredicate(
                    format: "%K == nil",
                    argumentArray: [keyPathValueProvider()]
                )
            }
        default:
            log.debug("Unhandled operator \(`operator`) and filterValue \(value)")
            return nil
        }
    }
}
