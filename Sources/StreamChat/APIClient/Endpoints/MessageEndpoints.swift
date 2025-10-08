//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    static func editMessage(payload: MessageRequestBody, skipEnrichUrl: Bool, skipPush: Bool)
        -> Endpoint<EmptyResponse> {
        .init(
            path: .editMessage(payload.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message": AnyEncodable(payload),
                "skip_enrich_url": AnyEncodable(skipEnrichUrl),
                "skip_push": AnyEncodable(skipPush)
            ]
        )
    }
    
    static func pinMessage(messageId: MessageId, request: MessagePartialUpdateRequest)
        -> Endpoint<EmptyResponse> {
        .init(
            path: .pinMessage(messageId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }

    static func partialUpdateMessage(messageId: MessageId, request: MessagePartialUpdateRequest)
        -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: .editMessage(messageId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
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

// MARK: - Helper data structures

struct MessagePartialUpdateRequest: Encodable {
    var set: SetProperties?
    var unset: [String]?
    var skipEnrichUrl: Bool?
    var userId: String?
    var user: UserRequestBody?

    /// The available message properties that can be updated.
    struct SetProperties: Encodable {
        var pinned: Bool?
        var text: String?
        var extraData: [String: RawJSON]?
        var attachments: [MessageAttachmentPayload]?

        enum CodingKeys: String, CodingKey {
            case text
            case pinned
            case extraData
            case attachments
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(text, forKey: .text)
            try container.encodeIfPresent(pinned, forKey: .pinned)
            try container.encodeIfPresent(attachments, forKey: .attachments)
            try extraData?.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        try container.encodeIfPresent(skipEnrichUrl, forKey: .skipEnrichUrl)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(set, forKey: .set)
        try container.encodeIfPresent(unset, forKey: .unset)
    }
}
