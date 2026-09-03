//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func getMessage(messageId: MessageId) -> Endpoint<MessageResponse.Boxed> {
        .init(
            path: .message(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
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
}
