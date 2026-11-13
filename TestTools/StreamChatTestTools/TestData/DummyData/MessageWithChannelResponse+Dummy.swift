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
            message: .dummy(
                messageId: messageId,
                authorUserId: authorUserId,
                text: text,
                extraData: extraData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cid: cid
            ),
            channel: .dummy(cid: cid)
        )
    }
}
