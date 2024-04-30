//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    static func editMessage(payload: MessageRequestBody, skipEnrichUrl: Bool)
        -> Endpoint<EmptyResponse> {
        .init(
            path: .editMessage(payload.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message": AnyEncodable(payload),
                "skip_enrich_url": AnyEncodable(skipEnrichUrl)
            ]
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
