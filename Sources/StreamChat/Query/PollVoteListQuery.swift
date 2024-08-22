//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        filter: Filter<VoteListFilterScope>? = nil
    ) {
        self.pollId = pollId
        self.optionId = optionId
        self.pagination = pagination
        self.filter = filter
    }

    /// Creates a vote list query for the given pollId and the provided filter.
    public init(
        pollId: String,
        filter: Filter<VoteListFilterScope>? = nil,
        pagination: Pagination = .init(pageSize: 10, offset: 0)
    ) {
        self.pollId = pollId
        self.pagination = pagination
        self.filter = filter
    }

    /// Creates a vote list query for the given pollId and optionId.
    public init(
        pollId: String,
        optionId: String,
        pagination: Pagination = .init(pageSize: 10, offset: 0)
    ) {
        self.pollId = pollId
        self.optionId = optionId
        self.pagination = pagination
        filter = .equal(.optionId, to: optionId)
    }

    enum CodingKeys: CodingKey {
        case pagination
        case filter
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(filter, forKey: .filter)
        try pagination.encode(to: encoder)
    }
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
