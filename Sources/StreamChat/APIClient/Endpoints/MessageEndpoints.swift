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

// MARK: - Reminder Endpoints

extension Endpoint {
    // Creates or updates a reminder for a message
    static func createReminder(messageId: MessageId, request: ReminderRequestBody) -> Endpoint<ReminderResponsePayload> {
        .init(
            path: .reminder(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }
    
    // Updates an existing reminder for a message
    static func updateReminder(messageId: MessageId, request: ReminderRequestBody) -> Endpoint<ReminderResponsePayload> {
        .init(
            path: .reminder(messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }
    
    // Deletes a reminder for a message
    static func deleteReminder(messageId: MessageId, userId: UserId? = nil) -> Endpoint<EmptyResponse> {
        var body: [String: AnyEncodable]?
        if let userId = userId {
            body = ["user_id": AnyEncodable(userId)]
        }
        
        return .init(
            path: .reminder(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }
    
    // Queries reminders with the provided parameters
    static func queryReminders(query: MessageReminderListQuery) -> Endpoint<RemindersQueryPayload> {
        .init(
            path: .reminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: query
        )
    }
}

// MARK: - Helper data structures

struct MessagePartialUpdateRequest: Encodable {
    var set: SetProperties?
    var unset: [String]? = []
    var skipEnrichUrl: Bool?
    var userId: String?
    var user: UserRequestBody?

    /// The available message properties that can be updated.
    struct SetProperties: Encodable {
        var pinned: Bool?
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
