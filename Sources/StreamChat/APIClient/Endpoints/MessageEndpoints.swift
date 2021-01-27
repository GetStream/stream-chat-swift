//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func getMessage<ExtraData: ExtraDataTypes>(messageId: MessageId) -> Endpoint<MessagePayload<ExtraData>> {
        .init(
            path: messageId.path,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func deleteMessage(messageId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: messageId.path,
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func editMessage<ExtraData: ExtraDataTypes>(payload: MessageRequestBody<ExtraData>)
        -> Endpoint<EmptyResponse> {
        .init(
            path: payload.id.path,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": payload]
        )
    }
    
    static func loadReplies<ExtraData: ExtraDataTypes>(messageId: MessageId, pagination: MessagesPagination)
        -> Endpoint<MessageRepliesPayload<ExtraData>> {
        .init(
            path: messageId.repliesPath,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
    }
    
    static func addReaction<ExtraData: MessageReactionExtraData>(
        _ type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        extraData: ExtraData,
        messageId: MessageId
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: messageId.reactionsPath,
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
            path: messageId.reactionsPath.appending("/\(type.rawValue)"),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func dispatchEphemeralMessageAction<ExtraData: ExtraDataTypes>(
        cid: ChannelId,
        messageId: MessageId,
        action: AttachmentAction
    ) -> Endpoint<MessagePayload<ExtraData>.Boxed> {
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
}

private extension MessageId {
    var path: String {
        "messages/\(self)"
    }
    
    var repliesPath: String {
        "messages/\(self)/replies"
    }
    
    var reactionsPath: String {
        path.appending("/reaction")
    }

    var actionPath: String {
        path.appending("/action")
    }
}
