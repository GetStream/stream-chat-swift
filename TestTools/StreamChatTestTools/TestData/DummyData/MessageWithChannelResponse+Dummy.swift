//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageWithChannelResponse {
    /// The get message endpoint returns the message with its channel embedded.
    static func dummy(
        messageId: MessageId = .unique,
        text: String = .unique,
        authorUserId: UserId = .unique,
        cid: ChannelId = .unique,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        extraData: [String: RawJSON] = [:]
    ) -> MessageWithChannelResponse {
        MessageWithChannelResponse(
            message: SearchResultMessage.dummy(
                messageId: messageId,
                text: text,
                authorUserId: authorUserId,
                cid: cid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                extraData: extraData
            ).message,
            channel: .dummy(cid: cid)
        )
    }
}
