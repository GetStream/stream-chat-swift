//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for ``GroupedChannelsQuery`` group filters.
public struct GroupedChannelsFilterScope: FilterScope {}

/// Filter keys for grouped channels.
public extension FilterKey where Scope == GroupedChannelsFilterScope {
    /// A filter key for matching the channel's stored group.
    /// Supported operators: `equal`, `in`, `notEqual`
    static var group: FilterKey<Scope, String> { "group" }

    /// A filter key for matching the channel's latest activity time.
    /// Supported operators: `greaterOrEqual`
    static var queryTimestamp: FilterKey<Scope, GroupedChannelsTimestamp> { "query_timestamp" }
}

/// A cutoff value for the `queryTimestamp` filter key of ``GroupedChannelsFilterScope``.
public enum GroupedChannelsTimestamp: FilterValue, Hashable {
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
