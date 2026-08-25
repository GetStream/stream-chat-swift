//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `BannedUserListQuery`. This scope is not aware of any extra data types.
public protocol AnyBannedUserListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `BannedUserListQuery`.
public struct BannedUserListFilterScope: FilterScope, AnyBannedUserListFilterScope {}

/// Filter keys for the banned user list.
public extension FilterKey where Scope == BannedUserListFilterScope {
    /// A filter key for matching the id of the banned user.
    /// Supported operators: `equal`, `notEqual`, `in`, `notIn`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `exists`
    static var userId: FilterKey<Scope, UserId> { "user_id" }

    /// A filter key for matching the id of the user who created the ban.
    /// Supported operators: `equal`, `notEqual`, `in`, `notIn`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `exists`
    static var bannedById: FilterKey<Scope, UserId> { "banned_by_id" }

    /// A filter key for matching the channel the ban is scoped to.
    /// Supported operators: `equal`, `in`
    static var cid: FilterKey<Scope, ChannelId> { "channel_cid" }

    /// A filter key for matching the date the ban was created at.
    /// Supported operators: `equal`, `notEqual`, `in`, `notIn`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `exists`
    static var createdAt: FilterKey<Scope, Date> { "created_at" }

    /// A filter key for matching the reason the ban was created with.
    /// Supported operators: `equal`, `notEqual`, `in`, `notIn`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `exists`, `autocomplete`
    static var reason: FilterKey<Scope, String> { "reason" }
}

/// The type describing a value that can be used for sorting when querying banned users.
public struct BannedUserListSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The supported sorting keys for banned users.
public extension BannedUserListSortingKey {
    /// Sorts banned users by the `created_at` field.
    static let createdAt = Self(rawValue: "created_at")
}

/// A query is used for querying banned users from the backend.
/// You can specify filter, sorting, and pagination options.
///
/// - Important: Client-side requests must filter on `cid`. The backend rejects a query without a
/// channel filter, so app-wide bans can only be queried server-side.
public struct BannedUserListQuery: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case excludeExpiredBans = "exclude_expired_bans"
    }

    /// A filter for the query (see `Filter`).
    public let filter: Filter<BannedUserListFilterScope>?
    /// A sorting for the query (see `Sorting`). When empty, the backend sorts ascending by `created_at`.
    public let sort: [Sorting<BannedUserListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    /// A Boolean value indicating whether bans which have already expired should be left out of the results.
    public let excludeExpiredBans: Bool

    /// Init a banned users query.
    /// - Parameters:
    ///   - filter: a banned users filter.
    ///   - sort: a sorting list for banned users. Only ``BannedUserListSortingKey/createdAt`` is supported by the backend.
    ///   - pagination: a pagination for the query. The maximum page size is 300.
    ///   - excludeExpiredBans: whether bans which have already expired should be left out of the results.
    public init(
        filter: Filter<BannedUserListFilterScope>? = nil,
        sort: [Sorting<BannedUserListSortingKey>] = [],
        pagination: Pagination = Pagination(pageSize: .bannedUsersPageSize),
        excludeExpiredBans: Bool = false
    ) {
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.excludeExpiredBans = excludeExpiredBans
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let filter = filter {
            try container.encode(filter, forKey: .filter)
        }

        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }

        if excludeExpiredBans {
            try container.encode(excludeExpiredBans, forKey: .excludeExpiredBans)
        }

        try pagination.encode(to: encoder)
    }
}

extension BannedUserListQuery: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Filter: \(String(describing: filter)) | Sort: \(sort)"
    }
}

extension BannedUserListQuery {
    /// Builds a query returning the bans scoped to the given channel, narrowed down by an optional additional filter.
    static func channelBans(
        cid: ChannelId,
        filter: Filter<BannedUserListFilterScope>?,
        sort: [Sorting<BannedUserListSortingKey>],
        pagination: Pagination,
        excludeExpiredBans: Bool
    ) -> Self {
        let channelFilter: Filter<BannedUserListFilterScope> = .equal(.cid, to: cid)
        return .init(
            filter: filter.map { .and([channelFilter, $0]) } ?? channelFilter,
            sort: sort,
            pagination: pagination,
            excludeExpiredBans: excludeExpiredBans
        )
    }
}

extension BannedUserListQuery {
    func asQueryBannedUsersPayload() -> QueryBannedUsersPayload {
        let sort = self.sort.map {
            SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.rawValue)
        }
        return QueryBannedUsersPayload(
            excludeExpiredBans: excludeExpiredBans ? true : nil,
            filterConditions: filter ?? EmptyObject(),
            limit: pagination.pageSize,
            offset: pagination.offset == 0 ? nil : pagination.offset,
            sort: sort.isEmpty ? nil : sort
        )
    }
}

// Backend expects empty object for "filter_conditions" in case no filter specified.
private struct EmptyObject: Encodable {}
