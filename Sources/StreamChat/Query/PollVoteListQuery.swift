//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query used for querying specific votes from a poll.
public struct PollVoteListQuery: Encodable {
    /// The pollId which the votes belong to.
    public var pollId: String
    /// The optionId which the votes belong to in case the query relates to only one poll option.
    public var optionId: String?
    /// The pagination information to query the votes.
    public var pagination: Pagination
    /// The sorting parameter. By default votes are sorted by newest first.
    public var sorting: [Sorting<PollVoteListSortingKey>]
    /// The filter details to query the votes.
    public var filter: Filter<VoteListFilterScope>?

    @available(
        *,
        deprecated,
        message: """
        There are now two new initializers.
        This one was not using the optionId argument correctly.
        """
    )
    public init(
        pollId: String,
        optionId: String?,
        pagination: Pagination = .init(pageSize: 10, offset: 0),
        sorting: [Sorting<PollVoteListSortingKey>] = [.init(key: .createdAt, isAscending: false)],
        filter: Filter<VoteListFilterScope>? = nil
    ) {
        self.pollId = pollId
        self.optionId = optionId
        self.pagination = pagination
        self.sorting = sorting
        self.filter = filter
    }

    /// Creates a vote list query for the given pollId and the provided filter.
    public init(
        pollId: String,
        filter: Filter<VoteListFilterScope>? = nil,
        pagination: Pagination = .init(pageSize: 10, offset: 0),
        sorting: [Sorting<PollVoteListSortingKey>] = [.init(key: .createdAt, isAscending: false)]
    ) {
        self.pollId = pollId
        self.pagination = pagination
        self.sorting = sorting
        self.filter = filter
    }

    /// Creates a vote list query for the given pollId and optionId.
    public init(
        pollId: String,
        optionId: String,
        pagination: Pagination = .init(pageSize: 10, offset: 0),
        sorting: [Sorting<PollVoteListSortingKey>] = [.init(key: .createdAt, isAscending: false)]
    ) {
        self.pollId = pollId
        self.optionId = optionId
        self.pagination = pagination
        self.sorting = sorting
        filter = .equal(.optionId, to: optionId)
    }

    enum CodingKeys: CodingKey {
        case pagination
        case filter
        case sort
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(filter, forKey: .filter)
        if !sorting.isEmpty {
            try container.encode(sorting, forKey: .sort)
        }
        try pagination.encode(to: encoder)
    }
}

/// The type describing a value that can be used as a sorting when paginating a list of votes in a poll.
public struct PollVoteListSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension PollVoteListSortingKey {
    /// Sorts votes by `created_at` field.
    static let createdAt = Self(rawValue: PollVotePayload.CodingKeys.createdAt.rawValue)
}

/// A namespace for the `FilterKey`s suitable to be used for `PollVoteListQuery`.
public protocol AnyVoteListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `PollVoteListQuery`.
public class VoteListFilterScope: FilterScope, AnyVoteListFilterScope {}

/// Non extra-data-specific filer keys for vote list.
public extension FilterKey where Scope: AnyVoteListFilterScope {
    /// A filter key for matching the option id.
    static var optionId: FilterKey<Scope, String> { "option_id" }

    /// A filter key for matching the user id of the vote's author.
    static var userId: FilterKey<Scope, UserId> { "user_id" }
    
    /// A filter key for matching the poll id.
    static var pollId: FilterKey<Scope, String> { "poll_id" }
    
    /// A filter that determines whether a vote is an answer.
    static var isAnswer: FilterKey<Scope, Bool> { "is_answer" }
}

extension PollVoteListQuery {
    var queryHash: String {
        [
            pollId,
            optionId,
            filter?.filterHash
        ].compactMap { $0 }.joined(separator: "-")
    }
}
