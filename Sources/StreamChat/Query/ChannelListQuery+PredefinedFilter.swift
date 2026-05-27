//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// MARK: - Filter

extension Filter where Scope == ChannelListFilterScope {
    /// Decodes a channel-list filter from persisted JSON and re-attaches Core Data wiring
    /// (keyPath, valueMapper, predicateMapper) for every node whose key matches a known
    /// `FilterKey<ChannelListFilterScope, _>`. Unknown keys pass through unchanged.
    static func predefinedFilter(fromJSONData data: Data) throws -> Filter {
        let decoded = try JSONDecoder.default.decode(Filter.self, from: data)
        return decoded.applyCoreDataFilteringKeys()
    }

    /// Walks the filter tree and replaces each leaf with an enriched copy that carries
    /// the Core Data wiring for its key. Group operators (`$and` / `$or` / `$nor`) recurse.
    private func applyCoreDataFilteringKeys() -> Filter {
        if `operator`.isGroupOperator {
            guard let children = value as? [Filter] else {
                return self
            }
            return Filter(
                operator: `operator`,
                key: nil,
                value: children.map { $0.applyCoreDataFilteringKeys() },
                isCollectionFilter: false
            )
        }
        guard let key else { return self }
        guard let coreDataMetadata = ChannelListFilterScope.predefinedFilterKeyMapping[key] else {
            StreamCore.log.error("Unknown channel list filtering key '\(key)' - dropping from local predefined filter.")
            return self
        }
        return Filter(
            operator: `operator`,
            key: key,
            value: value,
            valueMapper: coreDataMetadata.valueMapper,
            keyPathString: coreDataMetadata.keyPathString,
            isCollectionFilter: coreDataMetadata.isCollectionFilter,
            predicateMapper: coreDataMetadata.predicateMapper
        )
    }
}

/// Type-erased Core Data metadata extracted from a typed `FilterKey<ChannelListFilterScope, _>`.
/// The metadata is what `Filter+predicate.swift` consumes when building `NSPredicate`s.
struct ChannelListFilterKeyCoreDataMetadata: Sendable {
    let keyPathString: String?
    let valueMapper: (@Sendable (Any) -> FilterValue?)?
    let predicateMapper: (@Sendable (FilterOperator, Any) -> NSPredicate?)?
    let isCollectionFilter: Bool

    init<Value: FilterValue>(_ key: FilterKey<ChannelListFilterScope, Value>) {
        keyPathString = key.keyPathString
        valueMapper = key.valueMapper
        predicateMapper = key.predicateMapper
        isCollectionFilter = key.isCollectionFilter
    }
}

// MARK: - Sort

extension Array where Element == Sorting<ChannelListSortingKey> {
    /// Decodes a server-resolved sort array (`[{"field": ..., "direction": -1|1, ...}, ...]`).
    /// Unknown `field` values are dropped because they cannot map to a typed key.
    static func predefinedFilterSort(fromJSONData data: Data) throws -> [Sorting<ChannelListSortingKey>] {
        let raw = try JSONDecoder.default.decode([RawSortingItem].self, from: data)
        return raw.compactMap { item in
            guard let key = ChannelListSortingKey.predefinedSortingKeyMapping[item.field] else {
                StreamCore.log.error("Unknown channel list sorting field '\(item.field)' - dropping from decoded sort array.")
                return nil
            }
            return Sorting(key: key, isAscending: item.direction == 1)
        }
    }
}

private struct RawSortingItem: Decodable {
    let field: String
    let direction: Int
}
