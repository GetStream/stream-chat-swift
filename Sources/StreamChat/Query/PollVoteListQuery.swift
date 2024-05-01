//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query used for querying specific reactions from a message.
public struct PollVoteListQuery: Encodable {
    public var pollId: String
    public var optionId: String?
    /// The pagination information to query the reactions.
    public var pagination: Pagination
    /// The filter details to query the reactions.
    public var filter: Filter<VoteListFilterScope>?

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

/// A namespace for the `FilterKey`s suitable to be used for `ReactionListQuery`.
public protocol AnyVoteListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `ReactionListQuery`.
public class VoteListFilterScope: FilterScope, AnyVoteListFilterScope {}

/// Non extra-data-specific filer keys for reaction list.
public extension FilterKey where Scope: AnyVoteListFilterScope {
    /// A filter key for matching the reaction type
    static var optionId: FilterKey<Scope, String> { "option_id" }

    /// A filter key for matching the user id of the reaction's author.
    static var userId: FilterKey<Scope, UserId> { "user_id" }
    
    static var pollId: FilterKey<Scope, String> { "poll_id" }
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
