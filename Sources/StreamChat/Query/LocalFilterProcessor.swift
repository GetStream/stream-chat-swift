//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct LocalFilterProcessor<
    Scope: FilterScope,
    ResultType
> {
    var filter: Filter<Scope>

    func execute(
        _ items: [ResultType]
    ) -> [ResultType] {
        guard
            filter.key != nil,
            let `operator` = FilterOperator(rawValue: filter.operator),
            let keyToValueMapper = filter.keyToValueMapper
        else {
            return items
        }

        let mappedValues: [(item: ResultType, value: AnyFilterValue)] = items
            .compactMap {
                guard let value = keyToValueMapper($0) else { return nil }
                return (item: $0, value: value.eraseToAnyFilterValue())
            }
        let anyValue = filter.value.eraseToAnyFilterValue()

        switch `operator` {
        case .equal:
            return mappedValues.filter { $0.value == anyValue }.map(\.item)
        case .notEqual:
            return mappedValues.filter { $0.value != anyValue }.map(\.item)
        case .greater:
            return mappedValues.filter { $0.value > anyValue }.map(\.item)
        case .greaterOrEqual:
            return mappedValues.filter { $0.value >= anyValue }.map(\.item)
        case .less:
            return mappedValues.filter { $0.value < anyValue }.map(\.item)
        case .lessOrEqual:
            return mappedValues.filter { $0.value <= anyValue }.map(\.item)
        case .in:
            var result: [ResultType] = []
            if let inputValueSet = anyValue.valueSet {
                for mappedValue in mappedValues {
                    guard let mappedValueSet = mappedValue.value.valueSet else {
                        continue
                    }
                    if inputValueSet.intersection(mappedValueSet) == inputValueSet {
                        result.append(mappedValue.item)
                    }
                }
            }
            return result
        case .notIn:
            var result: [ResultType] = []
            if let inputValueSet = anyValue.valueSet {
                for mappedValue in mappedValues {
                    guard let mappedValueSet = mappedValue.value.valueSet else {
                        continue
                    }
                    if inputValueSet.subtracting(mappedValueSet) == inputValueSet {
                        result.append(mappedValue.item)
                    }
                }
            }
            return result
        case .query:
            //            return "\(key) QUERY \(value)"
            return []
        case .autocomplete:
            return mappedValues.filter { $0.value.contains(anyValue) }.map(\.item)
        case .exists:
            return mappedValues.filter { $0.value.contains(anyValue) }.map(\.item)
        case .contains:
            return mappedValues.filter { $0.value.contains(anyValue) }.map(\.item)
        case .and:
            let filters = filter.value as? [Filter<Scope>] ?? []
            var result: [ResultType] = []
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(
                    filter: subFilter
                ).execute(items)
                result += filterResults
            }

            if let hashableItems = result as? [AnyHashable] {
                return Array(Set(hashableItems)) as? [ResultType] ?? []
            } else {
                return result
            }
        case .or:
            let filters = filter.value as? [Filter<Scope>] ?? []
            for subFilter in filters {
                let filterResults = LocalFilterProcessor(
                    filter: subFilter
                ).execute(items)

                if !filterResults.isEmpty {
                    return filterResults
                }
            }
            return []
        case .nor:
            //            let filters = value as? [Filter] ?? []
            //            return "(" + filters.map(\.description).joined(separator: ") NOR (") + ")"
            return []
        }
    }
}
