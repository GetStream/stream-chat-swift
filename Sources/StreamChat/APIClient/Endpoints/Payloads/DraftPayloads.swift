//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct DraftPayloadResponse: Decodable {
    let draft: DraftPayload
}

struct DraftListPayloadResponse: Decodable {
    let drafts: [DraftPayload]
    let next: String?
}

struct DraftPayload: Decodable {
    let cid: ChannelId?
    let channelPayload: ChannelDetailPayload?
    let createdAt: Date
    let message: DraftMessagePayload
    let quotedMessage: MessagePayload?
    let parentId: String?
    let parentMessage: MessagePayload?

    init(
        cid: ChannelId?,
        channelPayload: ChannelDetailPayload?,
        createdAt: Date,
        message: DraftMessagePayload,
        quotedMessage: MessagePayload?,
        parentId: String?,
        parentMessage: MessagePayload?
    ) {
        self.cid = cid
        self.channelPayload = channelPayload
        self.createdAt = createdAt
        self.message = message
        self.quotedMessage = quotedMessage
        self.parentId = parentId
        self.parentMessage = parentMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        cid = try container.decodeIfPresent(ChannelId.self, forKey: .channelId)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        channelPayload = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        quotedMessage = try container.decodeIfPresent(MessagePayload.self, forKey: .quotedMessage)
        parentMessage = try container.decodeIfPresent(MessagePayload.self, forKey: .parentMessage)
        message = try container.decode(DraftMessagePayload.self, forKey: .message)
    }
}

struct DraftMessagePayload: Decodable {
    let id: String
    let text: String
    let command: String?
    let args: String?
    let showReplyInChannel: Bool
    let mentionedUsers: [UserPayload]?
    let extraData: [String: RawJSON]
    let attachments: [MessageAttachmentPayload]?
    let isSilent: Bool

    init(
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
        self.id = id
        self.text = text
        self.command = command
        self.args = args
        self.showReplyInChannel = showReplyInChannel
        self.mentionedUsers = mentionedUsers
        self.extraData = extraData
        self.attachments = attachments
        self.isSilent = isSilent
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        mentionedUsers = try container.decodeIfPresent([UserPayload].self, forKey: .mentionedUsers)
        attachments = try container.decodeIfPresent([MessageAttachmentPayload].self, forKey: .attachments)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: MessagePayloadsCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }
    }
}

struct DraftMessageRequestBody: Encodable {
    let id: String
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let isSilent: Bool
    let quotedMessageId: String?
    let attachments: [MessageAttachmentPayload]
    let mentionedUserIds: [UserId]
    let extraData: [String: RawJSON]

    init(
        id: String,
        text: String,
        command: String?,
        args: String?,
        parentId: String?,
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: String?,
        attachments: [MessageAttachmentPayload],
        mentionedUserIds: [UserId],
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.text = text
        self.command = command
        self.args = args
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        self.isSilent = isSilent
        self.quotedMessageId = quotedMessageId
        self.attachments = attachments
        self.mentionedUserIds = mentionedUserIds
        self.extraData = extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encodeIfPresent(showReplyInChannel, forKey: .showReplyInChannel)
        try container.encodeIfPresent(quotedMessageId, forKey: .quotedMessageId)
        try container.encode(isSilent, forKey: .isSilent)

        if !attachments.isEmpty {
            try container.encode(attachments, forKey: .attachments)
        }

        if !mentionedUserIds.isEmpty {
            try container.encode(mentionedUserIds, forKey: .mentionedUsers)
        }

        try extraData.encode(to: encoder)
    }
}
