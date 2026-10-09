//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `ScheduledMessageListQuery`.
public struct ScheduledMessageListFilterScope: FilterScope {}

/// Filter keys for the scheduled message list.
public extension FilterKey where Scope == ScheduledMessageListFilterScope {
    /// A filter key for matching the `cid` value.
    /// Supported operators: `equal`
    static var cid: FilterKey<Scope, ChannelId> { .init(rawValue: "cid", keyPathString: "cid", valueMapper: { $0.rawValue }) }

    /// A filter key for matching the `status` value.
    /// Supported operators: `in`, `equal`
    static var status: FilterKey<Scope, String> { .init(rawValue: "status", keyPathString: "status") }
}

public extension Filter where Scope == ScheduledMessageListFilterScope {
    /// Returns a filter that matches the scheduled messages waiting to be sent.
    static var pending: Filter<Scope> {
        .in(.status, values: [ScheduledMessageStatus.scheduled.rawValue, ScheduledMessageStatus.sending.rawValue])
    }

    /// Returns a filter that matches the scheduled messages that could not be sent.
    static var failed: Filter<Scope> {
        .equal(.status, to: ScheduledMessageStatus.failed.rawValue)
    }
}

/// The type describing a value that can be used for sorting when querying scheduled messages.
public struct ScheduledMessageListSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The supported sorting keys for scheduled messages.
public extension ScheduledMessageListSortingKey {
    /// Sorts scheduled messages by `scheduled_at`.
    static let scheduledAt = Self(rawValue: "scheduled_at")

    /// Sorts scheduled messages by `created_at`.
    static let createdAt = Self(rawValue: "created_at")
}

/// A query for the current user's scheduled messages.
///
/// Without a sorting, pending messages come first and failed ones after, each sorted by `scheduledAt`.
public struct ScheduledMessageListQuery: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case filter
        case sort
    }

    /// A filter for the query (see `Filter`).
    public let filter: Filter<ScheduledMessageListFilterScope>?
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<ScheduledMessageListSortingKey>]
    /// A pagination.
    public var pagination: Pagination

    /// Creates a scheduled messages query.
    /// - Parameters:
    ///   - filter: A scheduled messages filter.
    ///   - sort: A sorting list for scheduled messages.
    ///   - pageSize: A page size for pagination. A user has at most 100 pending messages, so the default page holds all of them.
    ///   - next: A token for fetching the next page.
    public init(
        filter: Filter<ScheduledMessageListFilterScope>? = nil,
        sort: [Sorting<ScheduledMessageListSortingKey>] = [],
        pageSize: Int = 100,
        next: String? = nil
    ) {
        self.filter = filter
        self.sort = sort
        pagination = Pagination(pageSize: pageSize, cursor: next)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let filter = filter {
            try container.encode(filter, forKey: .filter)
        }

        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }

        try pagination.encode(to: encoder)
    }
}

extension ScheduledMessageListQuery: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Filter: \(String(describing: filter)) | Sort: \(sort)"
    }
}
