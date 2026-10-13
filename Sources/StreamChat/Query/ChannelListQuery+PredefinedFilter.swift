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
    static func predefinedFilter(fromJSONData data: Data) throws -> Filter? {
        guard !data.isEmpty else { return nil }
        let decoded = try JSONDecoder.default.decode(Filter.self, from: data)
        return decoded.applyingCoreDataFilteringKeys(ChannelListFilterScope.predefinedFilterKeyMapping)
    }
}

extension Filter {
    /// Walks the filter tree and replaces each leaf with an enriched copy that carries
    /// the Core Data wiring for its key. Group operators (`$and` / `$or` / `$nor`) recurse.
    func applyingCoreDataFilteringKeys(_ mapping: [String: @Sendable (Filter) -> Filter]) -> Filter {
        if `operator`.isGroupOperator {
            guard let children = value as? [Filter] else {
                return self
            }
            return Filter(
                operator: `operator`,
                key: key,
                value: children.map { $0.applyingCoreDataFilteringKeys(mapping) },
                isCollectionFilter: isCollectionFilter
            )
        }
        guard let key else { return self }
        guard let mapFilter = mapping[key] else {
            StreamCore.log.error("Can't apply CoreData keyPath for filtering key '\(key)'.")
            return self
        }
        return mapFilter(self)
    }

    var hasCoreDataWiringOnEveryLeaf: Bool {
        if `operator`.isGroupOperator {
            return (value as? [Filter])?.allSatisfy(\.hasCoreDataWiringOnEveryLeaf) ?? false
        }
        return keyPathString != nil
    }
}

// MARK: - Sort

extension Array where Element == Sorting<ChannelListSortingKey> {
    /// Decodes a server-resolved sort array (`[{"field": ..., "direction": -1|1, ...}, ...]`).
    static func predefinedFilterSort(fromJSONData data: Data) throws -> [Sorting<ChannelListSortingKey>]? {
        guard !data.isEmpty else { return nil }
        let raw = try JSONDecoder.default.decode([RawSortingItem].self, from: data)
        return raw.compactMap { item in
            guard let key = ChannelListSortingKey.predefinedSortingKeyMapping[item.field] else {
                StreamCore.log.error("Can't apply CoreData keyPath for channel list sorting key '\(item.field)'.")
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
