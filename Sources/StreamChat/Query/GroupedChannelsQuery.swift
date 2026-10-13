//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for ``GroupedChannelsQuery`` group filters.
public struct GroupedChannelsFilterScope: FilterScope {}

/// Filter keys for grouped channels.
public extension FilterKey where Scope == GroupedChannelsFilterScope {
    /// A filter key for matching the channel's stored group.
    /// Supported operators: `equal`, `in`
    static var group: FilterKey<Scope, String> { .init(
        rawValue: "group",
        keyPathString: #keyPath(ChannelDTO.group),
        valueMapper: { GroupedChannelKey.normalizedGroup($0) }
    ) }

    /// A filter key for matching the channel's latest activity time.
    /// Supported operators: `greaterOrEqual`
    static var queryTimestamp: FilterKey<Scope, GroupedChannelsTimestamp> { .init(
        rawValue: "query_timestamp",
        keyPathString: #keyPath(ChannelDTO.defaultSortingAt),
        valueMapper: { $0.cutoffDate }
    ) }
}

/// A cutoff value for the `queryTimestamp` filter key of ``GroupedChannelsFilterScope``.
public enum GroupedChannelsTimestamp: FilterValue {
    /// A cutoff relative to the time the request is handled, in whole days. The backend resolves it on every request,
    /// so loading more channels and refreshing after a reconnect keep the cutoff rolling.
    case daysAgo(Int)
    /// A fixed cutoff date.
    case date(Date)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .daysAgo(days):
            try container.encode("now-\(days)d")
        case let .date(date):
            try container.encode(date)
        }
    }
}

extension GroupedChannelsTimestamp {
    init?(filterValue: FilterValue) {
        if let date = filterValue as? Date {
            self = .date(date)
            return
        }
        guard let string = filterValue as? String else { return nil }
        let relative = string.hasPrefix("now-") ? string.dropFirst(4) : Substring(string)
        guard relative.hasSuffix("d"), let days = Int(relative.dropLast()) else { return nil }
        self = .daysAgo(days)
    }

    var cutoffDate: Date {
        switch self {
        case let .daysAgo(days):
            return Date().addingTimeInterval(-TimeInterval(days) * 86400)
        case let .date(date):
            return date
        }
    }
}

extension GroupedChannelsFilterScope {
    static let keyMapping: [String: @Sendable (Filter<Self>) -> Filter<Self>] = [
        FilterKey<Self, String>.group.rawValue: { filter in
            filter.withLocalWiring(of: .group, value: filter.value, predicateMapper: groupPredicateMapper)
        },
        FilterKey<Self, GroupedChannelsTimestamp>.queryTimestamp.rawValue: { filter in
            // A cutoff that can't be parsed stays unwired, which disables the whole filter locally.
            guard let cutoff = GroupedChannelsTimestamp(filterValue: filter.value) else { return filter }
            return filter.withLocalWiring(of: .queryTimestamp, value: cutoff)
        }
    ]

    // The default `$in` predicate (`%@ IN %K`) is a substring match on a string key path.
    private static let groupPredicateMapper: Filter<Self>.PredicateMapper = { op, values in
        guard op == .in, let values = values as? [String] else { return nil }
        let groups = values.compactMap(GroupedChannelKey.normalizedGroup)
        return NSPredicate(format: "%K IN %@", argumentArray: [#keyPath(ChannelDTO.group), groups])
    }
}

extension Filter where Scope == GroupedChannelsFilterScope {
    static func groupedFilter(fromJSONData data: Data) throws -> Filter? {
        guard !data.isEmpty else { return nil }
        let decoded = try JSONDecoder.default.decode(Filter.self, from: data)
        let wired = decoded.applyingCoreDataFilteringKeys(GroupedChannelsFilterScope.keyMapping)
        // Dropping a single unsupported leaf would change `$or` / `$nor` results, so the backend decides instead.
        return wired.hasCoreDataWiringOnEveryLeaf ? wired : nil
    }

    fileprivate func withLocalWiring<Value: FilterValue>(
        of key: FilterKey<Scope, Value>,
        value: FilterValue,
        predicateMapper: PredicateMapper? = nil
    ) -> Filter {
        Filter(
            operator: `operator`,
            key: self.key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString,
            isCollectionFilter: key.isCollectionFilter,
            predicateMapper: predicateMapper ?? key.predicateMapper
        )
    }
}

/// The type describing a value that can be used for sorting when querying grouped channels.
public struct GroupedChannelsSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The supported sorting keys for grouped channels.
public extension GroupedChannelsSortingKey {
    /// Sorts channels by their latest activity time. Required when any group has a filter.
    static let queryTimestamp = Self(rawValue: "query_timestamp")
}

/// A query for fetching the first page of several channel groups in a single request.
///
/// Each group can have a filter. Filters require sorting by ``GroupedChannelsSortingKey/queryTimestamp``.
///
/// ```swift
/// let query = GroupedChannelsQuery(
///     groups: [
///         .init(key: "all", filter: .or([
///             .and([.equal(.group, to: "ended"), .greaterOrEqual(.queryTimestamp, than: .daysAgo(7))]),
///             .in(.group, values: ["campaign", "new"])
///         ])),
///         .init(key: "new"),
///         .init(key: "expired", filter: .greaterOrEqual(.queryTimestamp, than: .daysAgo(14)))
///     ],
///     sort: [.init(key: .queryTimestamp)],
///     limit: 10
/// )
/// ```
public struct GroupedChannelsQuery: Sendable {
    /// A requested channel group.
    public struct Group: Sendable {
        /// The group key, for example `"all"` or a stored group name.
        public let key: String
        /// An optional filter for the group's channels. `nil` keeps the default grouping.
        public let filter: Filter<GroupedChannelsFilterScope>?

        /// Creates a requested channel group.
        /// - Parameters:
        ///   - key: The group key, for example `"all"` or a stored group name.
        ///   - filter: An optional filter for the group's channels. `nil` keeps the default grouping.
        public init(key: String, filter: Filter<GroupedChannelsFilterScope>? = nil) {
            self.key = key
            self.filter = filter
        }
    }

    /// The groups to fetch.
    public let groups: [Group]
    /// The sorting applied to every group. Empty keeps the default ordering.
    public let sort: [Sorting<GroupedChannelsSortingKey>]
    /// The number of channels to return per group. `nil` uses the backend default.
    public let limit: Int?
    /// When `true`, includes presence info and streams presence updates over the WebSocket.
    public let presence: Bool
    /// When `true`, subscribes to WebSocket events for the returned channels.
    public let watch: Bool

    /// Creates a grouped channels query.
    /// - Parameters:
    ///   - groups: The groups to fetch.
    ///   - sort: The sorting applied to every group. Empty keeps the default ordering.
    ///   - limit: The number of channels to return per group. `nil` uses the backend default.
    ///   - presence: When `true`, includes presence info and streams presence updates over the WebSocket.
    ///   - watch: When `true`, subscribes to WebSocket events for the returned channels.
    public init(
        groups: [Group],
        sort: [Sorting<GroupedChannelsSortingKey>] = [],
        limit: Int? = nil,
        presence: Bool = false,
        watch: Bool = true
    ) {
        self.groups = groups
        self.sort = sort
        self.limit = limit
        self.presence = presence
        self.watch = watch
    }
}

extension GroupedChannelsQuery {
    var groupRequests: [String: GroupedChannelsGroupRequest]? {
        guard !groups.isEmpty else { return nil }
        return groups.reduce(into: [:]) { result, group in
            result[group.key] = GroupedChannelsGroupRequest(filterConditions: group.filter)
        }
    }

    var sortRequests: [SortParamRequest]? {
        guard !sort.isEmpty else { return nil }
        return sort.map { SortParamRequest(direction: $0.direction, field: $0.key.rawValue) }
    }
}
