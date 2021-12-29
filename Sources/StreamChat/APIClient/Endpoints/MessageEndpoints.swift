//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func getMessage(messageId: MessageId) -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: messageId.path,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func deleteMessage(messageId: MessageId, hard: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: messageId.path,
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["hard": hard]
        )
    }
    
    static func editMessage(payload: MessageRequestBody)
        -> Endpoint<EmptyResponse> {
        .init(
            path: payload.id.path,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": payload]
        )
    }
    
    static func loadReplies(messageId: MessageId, pagination: MessagesPagination)
        -> Endpoint<MessageRepliesPayload> {
        .init(
            path: messageId.repliesPath,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
    }

    static func loadReactions(messageId: MessageId, pagination: Pagination) -> Endpoint<MessageReactionsPayload> {
        .init(
            path: messageId.reactionsPath,
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
        .init(
            path: messageId.reactionPath,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "reaction": MessageReactionRequestPayload(
                    type: type,
                    score: score,
                    enforceUnique: enforceUnique,
                    extraData: extraData
                )
            ]
        )
    }
    
    static func deleteReaction(_ type: MessageReactionType, messageId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: messageId.reactionPath.appending("/\(type.rawValue)"),
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
            path: messageId.actionPath,
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
        .init(path: "search", method: .get, queryItems: nil, requiresConnectionId: false, body: ["payload": query])
    }
}

private extension MessageId {
    var path: String {
        "messages/\(self)"
    }
    
    var repliesPath: String {
        "messages/\(self)/replies"
    }

    var reactionsPath: String {
        "messages/\(self)/reactions"
    }
    
    var reactionPath: String {
        path.appending("/reaction")
    }

    var actionPath: String {
        path.appending("/action")
    }
}
