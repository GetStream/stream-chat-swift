//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func loadReactions(messageId: MessageId, pagination: Pagination) -> Endpoint<MessageReactionsPayload> {
        .init(
            path: .reactions(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
    }

    static func loadReactionsV2(query: ReactionListQuery) -> Endpoint<MessageReactionsPayload> {
        .init(
            path: .reactions(query.messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: query
        )
    }

    static func addReaction(
        _ type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        extraData: [String: RawJSON],
        messageId: MessageId
    ) -> Endpoint<EmptyResponse> {
        let body = MessageReactionRequestPayload(
            enforceUnique: enforceUnique,
            reaction: ReactionRequestPayload(
                type: type,
                score: score,
                extraData: extraData
            )
        )
        return .init(
            path: .addReaction(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func deleteReaction(_ type: MessageReactionType, messageId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: .deleteReaction(messageId, type),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
