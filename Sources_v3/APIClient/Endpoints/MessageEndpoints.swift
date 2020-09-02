//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
}

private extension MessageId {
    var path: String {
        "messages/\(self)"
    }
}
