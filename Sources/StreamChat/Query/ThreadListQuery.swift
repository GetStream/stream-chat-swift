//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query to fetch the list of threads the current belongs to.
public struct ThreadListQuery: Encodable, Sendable, LocalConvertibleSortingQuery {
    private enum CodingKeys: String, CodingKey {
        case filter
        case sort
        case watch
        case replyLimit = "reply_limit"
        case participantLimit = "participant_limit"
        case limit
        case next
    }

    /// A filter for the query.
    public let filter: Filter<ThreadListFilterScope>?
    /// A sorting for the query.
    /// By default it is sorted by unread state, last message date, and parent message ID.
    public let sort: [Sorting<ThreadListSortingKey>]
    /// A boolean indicating whether to watch for changes in the thread or not.
    public var watch: Bool
    /// The amount of threads fetched per page. Default is 20.
    public var limit: Int
    /// The amount of replies fetched per thread. Default is 3.
    public var replyLimit: Int
    /// The amount of participants fetched per thread. Default is 10.
    public var participantLimit: Int
    /// The pagination token from the previous response to fetch the next page.
    public var next: String?

    public init(
        watch: Bool,
        filter: Filter<ThreadListFilterScope>? = nil,
        sort: [Sorting<ThreadListSortingKey>] = [
            .init(key: .hasUnread),
            .init(key: .lastMessageAt),
            .init(key: .parentMessageId)
        ],
        limit: Int = 20,
        replyLimit: Int = 3,
        participantLimit: Int = 10,
        next: String? = nil
    ) {
        self.watch = watch
        self.filter = filter
        self.sort = sort
        self.limit = limit
        self.replyLimit = replyLimit
        self.participantLimit = participantLimit
        self.next = next
    }
}

/// A namespace for the `FilterKey`s suitable to be used for `ThreadListQuery`. This scope is not aware of any extra data types.
public protocol AnyThreadListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `ThreadListQuery`.
public struct ThreadListFilterScope: FilterScope, AnyThreadListFilterScope {}

/// The `Filter` keys that can be used to filter the threads in a `ThreadListQuery`.
public extension FilterKey where Scope == ThreadListFilterScope {
    /// A filter key for matching the `ChannelId` value.
    /// Supported operators: `equal`, `exists`.
    static var cid: FilterKey<Scope, String> { .init(
        rawValue: "channel_cid",
        keyPathString: #keyPath(ThreadDTO.channel.cid)
    ) }

    /// A filter key for matching the `createdAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `exists`.
    static var createdAt: FilterKey<Scope, Date> {
        .init(
            rawValue: "created_at",
            keyPathString: #keyPath(ThreadDTO.createdAt)
        )
    }

    /// A filter key for matching the `updatedAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`.
    static var updatedAt: FilterKey<Scope, Date> {
        .init(
            rawValue: "updated_at",
            keyPathString: #keyPath(ThreadDTO.updatedAt)
        )
    }

    /// A filter key for matching the `lastMessageAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`.
    static var lastMessageAt: FilterKey<Scope, Date> {
        .init(
            rawValue: "last_message_at",
            keyPathString: #keyPath(ThreadDTO.lastMessageAt)
        )
    }

    /// A filter key for matching the `createdByUserId` value.
    /// Supported operators: `equal`, `exists`.
    static var createdByUserId: FilterKey<Scope, UserId> {
        .init(
            rawValue: "created_by_user_id",
            keyPathString: #keyPath(ThreadDTO.createdBy.id)
        )
    }

    /// A filter key for matching the `parentMessageId` value.
    /// Supported operators: `equal`, `exists`.
    static var parentMessageId: FilterKey<Scope, MessageId> {
        .init(
            rawValue: "parent_message_id",
            keyPathString: #keyPath(ThreadDTO.parentMessageId)
        )
    }

    /// A filter key for querying disabled channels.
    /// Supported operators: `equal`.
    static var channelDisabled: FilterKey<Scope, Bool> {
        .init(
            rawValue: "channel.disabled",
            keyPathString: #keyPath(ThreadDTO.channel.isDisabled)
        )
    }
}

/// `ThreadListSortingKey` keys by which you can get sorted threads.
public typealias ThreadListSortingKey = LocalConvertibleSortingKey<ChatThread>

extension ThreadListSortingKey {
    /// Sort threads by date they were created.
    public static let createdAt = Self(
        keyPath: \.createdAt,
        localKey: #keyPath(ThreadDTO.createdAt),
        remoteKey: ThreadCodingKeys.createdAt.rawValue
    )

    /// Sort threads by date they were updated.
    public static let updatedAt = Self(
        keyPath: \.updatedAt,
        localKey: #keyPath(ThreadDTO.updatedAt),
        remoteKey: ThreadCodingKeys.updatedAt.rawValue
    )

    /// Sort threads by the last message date.
    public static let lastMessageAt = Self(
        keyPath: \.lastMessageAt,
        localKey: #keyPath(ThreadDTO.lastMessageAt),
        remoteKey: ThreadCodingKeys.lastMessageAt.rawValue
    )

    /// Sort threads by number of participants.
    public static let participantCount = Self(
        keyPath: \.participantCount,
        localKey: #keyPath(ThreadDTO.participantCount),
        remoteKey: ThreadCodingKeys.participantCount.rawValue
    )

    /// Sort threads by number of active participants.
    public static let activeParticipantCount = Self(
        keyPath: \.activeParticipantCount,
        localKey: #keyPath(ThreadDTO.activeParticipantCount),
        remoteKey: ThreadCodingKeys.activeParticipantCount.rawValue
    )

    /// Sort threads by number of replies.
    public static let replyCount = Self(
        keyPath: \.replyCount,
        localKey: #keyPath(ThreadDTO.replyCount),
        remoteKey: ThreadCodingKeys.replyCount.rawValue
    )

    /// Sort threads by `parentMessageId`.
    public static let parentMessageId = Self(
        keyPath: \.parentMessageId,
        localKey: #keyPath(ThreadDTO.parentMessageId),
        remoteKey: ThreadCodingKeys.parentMessageId.rawValue
    )

    /// Sort threads by unread state.
    public static let hasUnread = Self(
        localKey: #keyPath(ThreadDTO.currentUserUnreadCount),
        remoteKey: "has_unread"
    )
}
