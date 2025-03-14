//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `MessageReminderListQuery`. This scope is not aware of any extra data types.
public protocol AnyMessageReminderListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `MessageReminderListQuery`.
public struct MessageReminderListFilterScope: FilterScope, AnyMessageReminderListFilterScope {}

/// Filter keys for message reminder list.
public extension FilterKey where Scope: AnyMessageReminderListFilterScope {
    /// A filter key for matching the `channel_cid` value.
    /// Supported operators: `in`, `equal`
    static var channelCid: FilterKey<Scope, ChannelId> { .init(rawValue: "channel_cid", keyPathString: "channelCid", valueMapper: { $0.rawValue }) }
    
    /// A filter key for matching the `message_id` value.
    /// Supported operators: `in`, `equal`
    static var messageId: FilterKey<Scope, MessageId> { .init(rawValue: "message_id", keyPathString: "messageId") }
    
    /// A filter key for matching the `remind_at` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`
    static var remindAt: FilterKey<Scope, Date> { .init(rawValue: "remind_at", keyPathString: "remindAt") }
    
    /// A filter key for matching the `created_at` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`
    static var createdAt: FilterKey<Scope, Date> { .init(rawValue: "created_at", keyPathString: "createdAt") }
    
    /// A filter key for matching the `user_id` value.
    /// Supported operators: `in`, `equal`
    static var userId: FilterKey<Scope, UserId> { .init(rawValue: "user_id", keyPathString: "userId") }
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
public struct MessageReminderListQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter
        case sort
        case limit
        case next
        case prev
    }
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter<MessageReminderListFilterScope>?
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<MessageReminderListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    /// Next page token for pagination
    public var next: String?
    /// Previous page token for pagination
    public var prev: String?
    
    /// Init a message reminders query.
    /// - Parameters:
    ///   - filter: a reminders filter.
    ///   - sort: a sorting list for reminders.
    ///   - pageSize: a page size for pagination.
    ///   - next: a token for fetching the next page.
    ///   - prev: a token for fetching the previous page.
    public init(
        filter: Filter<MessageReminderListFilterScope>? = nil,
        sort: [Sorting<MessageReminderListSortingKey>] = [.init(key: .remindAt, isAscending: true)],
        pageSize: Int = 25,
        next: String? = nil,
        prev: String? = nil
    ) {
        self.filter = filter
        self.sort = sort
        pagination = Pagination(pageSize: pageSize)
        self.next = next
        self.prev = prev
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let filter = filter {
            try container.encode(filter, forKey: .filter)
        }
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try container.encode(pagination.pageSize, forKey: .limit)
        
        if let next = next {
            try container.encode(next, forKey: .next)
        }
        
        if let prev = prev {
            try container.encode(prev, forKey: .prev)
        }
    }
}

extension MessageReminderListQuery: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Filter: \(String(describing: filter)) | Sort: \(sort)"
    }
}
