//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func getMessage(messageId: MessageId) -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: .message(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteMessage(messageId: MessageId, hard: Bool) -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: .deleteMessage(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["hard": hard]
        )
    }

    static func editMessage(payload: MessageRequestBody)
        -> Endpoint<EmptyResponse> {
        .init(
            path: .editMessage(payload.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": payload]
        )
    }

    static func loadReplies(messageId: MessageId, pagination: MessagesPagination)
        -> Endpoint<MessageRepliesPayload> {
        .init(
            path: .replies(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
    }

    static func loadReactions(messageId: MessageId, pagination: Pagination) -> Endpoint<MessageReactionsPayload> {
        .init(
            path: .reactions(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
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

    static func dispatchEphemeralMessageAction(
        cid: ChannelId,
        messageId: MessageId,
        action: AttachmentAction
    ) -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: .messageAction(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: AttachmentActionRequestBody(
                cid: cid,
                messageId: messageId,
                action: action
            )
        )
    }

    static func search(query: MessageSearchQuery) -> Endpoint<MessageSearchResultsPayload> {
        .init(path: .search, method: .get, queryItems: nil, requiresConnectionId: false, body: ["payload": query])
    }

    static func translate(messageId: MessageId, to language: TranslationLanguage) -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: .translateMessage(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["language": language.languageCode]
        )
    }
}
