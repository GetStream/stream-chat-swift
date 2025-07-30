//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `MessageReminderListQuery`. This scope is not aware of any extra data types.
public protocol AnyMessageReminderListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `MessageReminderListQuery`.
public struct MessageReminderListFilterScope: FilterScope, AnyMessageReminderListFilterScope {}

/// Filter keys for message reminder list.
public extension FilterKey where Scope == MessageReminderListFilterScope {
    /// A filter key for matching the `channel_cid` value.
    /// Supported operators: `in`, `equal`
    static var cid: FilterKey<Scope, ChannelId> { .init(
        rawValue: "channel_cid",
        keyPathString: #keyPath(MessageReminderDTO.channel.cid),
        valueMapper: { $0.rawValue }
    ) }

    /// A filter key for matching the `remind_at` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`
    static var remindAt: FilterKey<Scope, Date> { .init(rawValue: "remind_at", keyPathString: #keyPath(MessageReminderDTO.remindAt)) }

    /// A filter key for matching the `created_at` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`
    static var createdAt: FilterKey<Scope, Date> { .init(rawValue: "created_at", keyPathString: #keyPath(MessageReminderDTO.createdAt)) }
}

public extension Filter where Scope == MessageReminderListFilterScope {
    /// Returns a filter that matches message reminders without a due date.
    static var withoutRemindAt: Filter<Scope> {
        .isNil(.remindAt)
    }

    /// Returns a filter that matches message reminders with a due date.
    static var withRemindAt: Filter<Scope> {
        .exists(.remindAt)
    }

    /// Returns a filter that matches message reminders that are overdue.
    static var overdue: Filter<Scope> {
        .lessOrEqual(.remindAt, than: Date())
    }

    /// Returns a filter that matches message reminders that are upcoming.
    static var upcoming: Filter<Scope> {
        .greaterOrEqual(.remindAt, than: Date())
    }
}

/// The type describing a value that can be used for sorting when querying message reminders.
public struct MessageReminderListSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The supported sorting keys for message reminders.
public extension MessageReminderListSortingKey {
    /// Sorts reminders by `remind_at` field.
    static let remindAt = Self(rawValue: "remind_at")
    
    /// Sorts reminders by `created_at` field.
    static let createdAt = Self(rawValue: "created_at")
    
    /// Sorts reminders by `updated_at` field.
    static let updatedAt = Self(rawValue: "updated_at")
}

/// A query is used for querying specific message reminders from backend.
/// You can specify filter, sorting, and pagination options.
public struct MessageReminderListQuery: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case filter
        case sort
    }
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter<MessageReminderListFilterScope>?
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<MessageReminderListSortingKey>]
    /// A pagination.
    public var pagination: Pagination

    /// Init a message reminders query.
    /// - Parameters:
    ///   - filter: a reminders filter.
    ///   - sort: a sorting list for reminders.
    ///   - pageSize: a page size for pagination.
    ///   - next: a token for fetching the next page.
    public init(
        filter: Filter<MessageReminderListFilterScope>? = nil,
        sort: [Sorting<MessageReminderListSortingKey>] = [.init(key: .remindAt, isAscending: true)],
        pageSize: Int = 25,
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

extension MessageReminderListQuery: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Filter: \(String(describing: filter)) | Sort: \(sort)"
    }
}
