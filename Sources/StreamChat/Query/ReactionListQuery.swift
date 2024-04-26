//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query used for querying specific reactions from a message.
public struct ReactionListQuery: Encodable {
    /// The pagination information to query the reactions.
    public var pagination: Pagination
    /// The filter details to query the reactions.
    public var filter: Filter<ReactionListFilterScope>?

    public init(pagination: Pagination, filter: Filter<ReactionListFilterScope>? = nil) {
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
public protocol AnyReactionListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `ReactionListQuery`.
public class ReactionListFilterScope: FilterScope, AnyReactionListFilterScope {}

/// Make the reaction type conform to FilterValue.
extension MessageReactionType: FilterValue {}

/// Non extra-data-specific filer keys for reaction list.
public extension FilterKey where Scope: AnyReactionListFilterScope {
    /// A filter key for matching the reaction type
    static var reactionType: FilterKey<Scope, MessageReactionType> { "type" }

    /// A filter key for matching the user id of the reaction's author.
    static var authorId: FilterKey<Scope, UserId> { "user_id" }
}
