//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    /// Creates a new `ChatReactionListController` with the provided reaction list query.
    ///
    /// - Parameter query: The query to specify which reactions should be fetch from the message.
    /// - Returns: A new instance of `ChatReactionListController`.
    public func reactionListController(query: ReactionListQuery) -> ChatReactionListController {
        .init(query: query, client: self)
    }

    /// Creates a new `ChatReactionListController` with the default query.
    /// It loads all reactions from the message.
    ///
    /// - Parameter messageId: The message id of the reactions to fetch.
    /// - Returns: A new instance of `ChatReactionListController`.
    public func reactionListController(for messageId: MessageId) -> ChatReactionListController {
        .init(
            query: ReactionListQuery(
                messageId: messageId,
                pagination: .init(pageSize: 25, offset: 0)
            ),
            client: self
        )
    }
}
