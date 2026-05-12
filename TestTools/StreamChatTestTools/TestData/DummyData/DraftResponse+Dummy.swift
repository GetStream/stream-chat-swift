//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DraftResponse {
    /// Returns dummy draft payload with the given values.
    static func dummy(
        cid: ChannelId? = nil,
        channelPayload: ChannelResponse? = nil,
        createdAt: Date = .unique,
        message: DraftPayloadResponse = .dummy(),
        quotedMessage: MessageResponse? = nil,
        parentId: String? = nil,
        parentMessage: MessageResponse? = nil
    ) -> DraftResponse {
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

extension DraftPayloadResponse {
    static func dummy(
        id: String = .unique,
        text: String = .unique,
        command: String? = nil,
        args: String? = nil,
        showReplyInChannel: Bool = false,
        mentionedUsers: [UserResponse]? = nil,
        extraData: [String: RawJSON] = [:],
        attachments: [Attachment]? = nil,
        isSilent: Bool = false
    ) -> DraftPayloadResponse {
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
