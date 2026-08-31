//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

typealias DraftListPayloadResponse = QueryDraftsResponse
typealias DraftPayloadResponse = GetDraftResponse

extension DraftPayload {
    // Generated properties are slightly different from the previously hand-written ones.
    convenience init(
        cid: ChannelId,
        channelPayload: ChannelDetailPayload?,
        createdAt: Date,
        message: DraftMessagePayload,
        quotedMessage: MessagePayload?,
        parentId: String?,
        parentMessage: MessagePayload?
    ) {
        self.init(
            channel: channelPayload,
            channelCid: cid.rawValue,
            createdAt: createdAt,
            message: message,
            parentId: parentId,
            parentMessage: parentMessage,
            quotedMessage: quotedMessage
        )
    }

    /// Returns dummy draft payload with the given values.
    static func dummy(
        cid: ChannelId,
        channelPayload: ChannelDetailPayload? = nil,
        createdAt: Date = .unique,
        message: DraftMessagePayload = .dummy(),
        quotedMessage: MessagePayload? = nil,
        parentId: String? = nil,
        parentMessage: MessagePayload? = nil
    ) -> DraftPayload {
        .init(
            channel: channelPayload,
            channelCid: cid.rawValue,
            createdAt: createdAt,
            message: message,
            parentId: parentId,
            parentMessage: parentMessage,
            quotedMessage: quotedMessage
        )
    }
}

extension DraftMessagePayload {
    convenience init(
        id: String,
        text: String,
        command: String?,
        args: String?,
        showReplyInChannel: Bool,
        mentionedUsers: [UserPayload]?,
        extraData: [String: RawJSON],
        attachments: [MessageAttachmentPayload]?,
        isSilent: Bool
    ) {
        var custom = extraData
        if let command {
            custom["command"] = .string(command)
        }
        if let args {
            custom["args"] = .string(args)
        }
        self.init(
            attachments: attachments,
            custom: custom,
            id: id,
            mentionedUsers: mentionedUsers,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text
        )
    }

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
