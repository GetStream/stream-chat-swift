//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    static func deleteMessage(messageId: MessageId, hard: Bool, deleteForMe: Bool? = nil) -> Endpoint<MessagePayload.Boxed> {
        var body: [String: AnyEncodable] = ["hard": AnyEncodable(hard)]
        if let deleteForMe = deleteForMe {
            body["delete_for_me"] = AnyEncodable(deleteForMe)
        }
        return .init(
            path: .deleteMessage(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
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
