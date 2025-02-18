//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DraftPayload {
    /// Returns dummy draft payload with the given values.
    static func dummy(
        cid: ChannelId? = nil,
        channelPayload: ChannelDetailPayload? = nil,
        createdAt: Date = .unique,
        message: DraftMessagePayload = .dummy(),
        quotedMessage: MessagePayload? = nil,
        parentId: String? = nil,
        parentMessage: MessagePayload? = nil
    ) -> DraftPayload {
        .init(
            cid: cid,
            channelPayload: channelPayload,
            createdAt: createdAt,
            message: message,
            quotedMessage: quotedMessage,
            parentId: parentId,
            parentMessage: parentMessage
        )
    }
}

extension DraftMessagePayload {
    static func dummy(
        id: String = .unique,
        text: String = .unique,
        command: String? = nil,
        args: String? = nil,
        showReplyInChannel: Bool = false,
        mentionedUsers: [UserPayload]? = nil,
        extraData: [String: RawJSON] = [:],
        attachments: [MessageAttachmentPayload]? = nil,
        isSilent: Bool = false
    ) -> DraftMessagePayload {
        .init(
            id: id,
            text: text,
            command: command,
            args: args,
            showReplyInChannel: showReplyInChannel,
            mentionedUsers: mentionedUsers,
            extraData: extraData,
            attachments: attachments,
            isSilent: isSilent
        )
    }
}
