//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - LocalFilterProcessor Implementation

/// LocalFilterProcessor can be initialised with any Filter and when called
/// match, it will process the filter and input data and will output which items
/// from the input data, match the filter.
///
/// **Known Limitations**
/// The following operator & FilterKey.Value combinations cannot be
/// processed from any instance of LocalFilterProcessor:
/// 1. .equal, .notEqual, .less, .lessOrEqual, .greater, .greaterOrEqual will only be
/// processed when the FilterKey.Value and the input data conform to Comparable
/// 2. .in, .notIn will only be processed if the FilterKey.Value and the input data are
/// arrays of Equatable items
/// 3. .autocomplete, .contains, .prefix will only be processed if the
/// FilterKey.Value and the input data are Strings
///
/// In the case where a LocalFilterProcessor cannot process a combination of
/// FilterKey.Value and the input data the following things will happen:
/// 1. a log message will be printed with sufficient information regarding the failure
/// 2. the input data will be return unprocessed
///
public struct LocalFilterProcessor<
    Scope: FilterScope
> {
    var filter: Filter<Scope>

    /// Creates a new instance of LocalFilterProcessor
    /// and assign a filter to it.
    ///
    /// - Parameters:
    /// - filter: The filter assigned to the LocalFilterProcessor. The filter will be used
    /// from `match` to process data input data.
    ///
    public init(
        filter: Filter<Scope>
    ) {
        self.filter = filter
    }

    /// Will attempt to filter the input data by processing in-memory
    /// the given filter.
    public func match<ResultType: Hashable>(
        _ inputItems: [ResultType]
    ) -> [ResultType] {
        if filter.value is [Filter<Scope>] {
            return matchLogicalFilterContainer(inputItems)
        }

        guard
            filter.key != nil,
            let `operator` = FilterOperator(rawValue: filter.operator),
            let keyToValueMapper = filter.keyToValueMapper
        else {
            return inputItems
        }

        let filterComparableValue = filter.value.eraseToAnyFilterValue()
        let inputMappedValues: [(item: ResultType, value: AnyFilterValue)] = inputItems.compactMap {
            guard let value = keyToValueMapper($0)?.eraseToAnyFilterValue() else {
                return nil
            }
            return (item: $0, value: value)
        }

        switch `operator` {
        case .equal, .notEqual, .greater, .greaterOrEqual, .less, .lessOrEqual:
            return inputMappedValues.filter {
                compare(
                    $0.value,
                    filterComparableValue,
                    operator: `operator`
                )
            }
            .map(\.item)
        case .in where filter.value is [FilterValue]:
            guard
                let filterArray = (filter.value as? [FilterValue])?.eraseToAnyFilterValue()
            else {
                return inputItems
            }
            return inputMappedValues
                .filter { $0.value.safeCast([FilterValue].self)?.eraseToAnyFilterValue().contains(filterArray) ?? false }
                .map(\.item)
        case .notIn where filter.value is [FilterValue]:
            guard
                let filterArray = (filter.value as? [FilterValue])?.eraseToAnyFilterValue()
            else {
                return inputItems
            }
            return inputMappedValues
                .filter { $0.value.safeCast([FilterValue].self)?.eraseToAnyFilterValue().contains(filterArray) == false }
                .map(\.item)
        case .autocomplete where filter.value is String:
            guard
                let prefix = filter.value as? String
            else {
                return inputItems
            }
            return inputMappedValues
                .filter { $0.value.safeCast(String.self)?.hasPrefix(prefix) == true }
                .map(\.item)
        case .contains where filter.value is String:
            guard
                let needle = filter.value as? String
            else {
                return inputItems
            }
            return inputMappedValues
                .filter { $0.value.safeCast(String.self)?.contains(needle) == true }
                .map(\.item)
        case .and where filter.value is [Filter<Scope>]:
            guard
                let filters = filter.value as? [Filter<Scope>]
            else {
                return inputItems
            }
            var result: Set<ResultType> = .init()
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(filter: subFilter)
                    .match(inputItems)
                if result.isEmpty {
                    result = result.union(filterResults)
                } else {
                    result = result.intersection(filterResults)
                }
            }
            return Array(result)
        case .or where filter.value is [Filter<Scope>]:
            guard
                let filters = filter.value as? [Filter<Scope>]
            else {
                return inputItems
            }
            var result: Set<ResultType> = .init()
            for subFilter in filters {
                LocalFilterProcessor(filter: subFilter)
                    .match(inputItems)
                    .forEach { result.insert($0) }
            }
            return Array(result)
        case .nor where filter.value is [Filter<Scope>]:
            guard
                let filters = filter.value as? [Filter<Scope>]
            else {
                return inputItems
            }
            let original = Set(inputItems)
            var result: Set<ResultType> = .init()
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(filter: subFilter)
                    .match(inputItems)
                let itemsNotExistingInFilterResults = original.subtracting(filterResults)
                let itemsNotExistingInCurrentResult = original.subtracting(result)
                result = itemsNotExistingInCurrentResult.intersection(itemsNotExistingInFilterResults)
            }
            return Array(result)
        default:
            log.debug("Unhandled operator \(`operator`) for items \(inputItems) and filterValue \(filter.value)")
            return inputItems
        }
    }

    private func matchLogicalFilterContainer<ResultType: Hashable>(
        _ inputItems: [ResultType]
    ) -> [ResultType] {
        guard
            let `operator` = FilterOperator(rawValue: filter.operator)
        else {
            return inputItems
        }

        switch `operator` {
        case .and where filter.value is [Filter<Scope>]:
            guard
                let filters = filter.value as? [Filter<Scope>]
            else {
                return inputItems
            }
            var result: Set<ResultType> = .init()
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(filter: subFilter)
                    .match(inputItems)
                if result.isEmpty {
                    result = result.union(filterResults)
                } else {
                    result = result.intersection(filterResults)
                }
            }
            return Array(result)
        case .or where filter.value is [Filter<Scope>]:
            guard
                let filters = filter.value as? [Filter<Scope>]
            else {
                return inputItems
            }
            var result: Set<ResultType> = .init()
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(filter: subFilter)
                    .match(inputItems)
                filterResults
                    .forEach { result.insert($0) }
            }
            return Array(result)
        case .nor where filter.value is [Filter<Scope>]: // TODO: Validate this one
            guard
                let filters = filter.value as? [Filter<Scope>]
            else {
                return inputItems
            }
            let original = Set(inputItems)
            var result: Set<ResultType> = .init()
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(filter: subFilter)
                    .match(inputItems)
                let itemsNotExistingInFilterResults = original.subtracting(filterResults)
                result = result.union(itemsNotExistingInFilterResults)
            }
            return Array(result)
        default:
            log.debug("Unhandled operator \(`operator`) for items \(inputItems) and filterValue \(filter.value)")
            return inputItems
        }
    }

    private func compare<E: Comparable>(
        _ lhs: E,
        _ rhs: E,
        operator: FilterOperator
    ) -> Bool {
        switch `operator` {
        case .equal:
            return lhs == rhs
        case .notEqual:
            return lhs != rhs
        case .greater:
            return lhs > rhs
        case .greaterOrEqual:
            return lhs >= rhs
        case .less:
            return lhs < rhs
        case .lessOrEqual:
            return lhs <= rhs
        default:
            return false
        }
    }
}

// MARK: - Public API

extension Filter {
    /// Creates a LocalFilterProcessor which will use this filter for every match call
    public func makeLocalProcessor() -> LocalFilterProcessor<Scope> {
        .init(filter: self)
    }
}

// MARK: - Internal Helpers

struct AnyFilterValue: Equatable, Comparable, Hashable {
    let rawValue: FilterValue

    init(
        _ rawValue: FilterValue
    ) {
        self.rawValue = rawValue
    }

    func safeCast<CastToType>(
        _ castToType: CastToType.Type
    ) -> CastToType? { rawValue as? CastToType }

    static func == (
        lhs: AnyFilterValue,
        rhs: AnyFilterValue
    ) -> Bool {
        guard
            let lhsEquatable = lhs.rawValue as? any Equatable,
            let rhsEquatable = rhs.rawValue as? any Equatable
        else {
            return false
        }
        return lhsEquatable.isEqual(rhsEquatable)
    }

    static func < (
        lhs: AnyFilterValue,
        rhs: AnyFilterValue
    ) -> Bool {
        guard
            let lhsEquatable = lhs.rawValue as? any Comparable,
            let rhsEquatable = rhs.rawValue as? any Comparable
        else {
            return false
        }
        return lhsEquatable.isLess(rhsEquatable)
    }

    func hash(
        into hasher: inout Hasher
    ) {
        guard let hashableValue = rawValue as? any Hashable else {
            hasher.combine(String.newUniqueId)
            return
        }
        hasher.combine(hashableValue)
    }
}

extension FilterValue {
    func eraseToAnyFilterValue() -> AnyFilterValue { .init(self) }
}

extension Array where Element == FilterValue {
    func eraseToAnyFilterValue() -> [AnyFilterValue] { map { $0.eraseToAnyFilterValue() } }
}

extension Array where Element == AnyFilterValue {
    func contains(
        _ array: [Element]
    ) -> Bool {
        let setArray = Set(array)
        let setSelf = Set(self)
        return setSelf.intersection(setArray) == setArray
    }
}

// MARK: - Fileprivate Helpers

extension Equatable {
    fileprivate func isEqual(
        _ other: any Equatable
    ) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

extension Comparable {
    fileprivate func isLess(
        _ other: any Comparable
    ) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self < other
    }
}
