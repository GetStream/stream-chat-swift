//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct DraftMessagePayloadResponse: Decodable {
    let draft: DraftMessagePayload
}

struct DraftMessagePayload: Decodable {
    let id: String
    let channelPayload: ChannelDetailPayload?
    let createdAt: Date
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let quotedMessageId: MessageId?
    let quotedMessage: MessagePayload?
    let mentionedUsers: [UserPayload]?
    let extraData: [String: RawJSON]
    let attachments: [MessageAttachmentPayload]
    let isSilent: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        channelPayload = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        text = try container.decode(String.self, forKey: .text).trimmingCharacters(in: .whitespacesAndNewlines)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        mentionedUsers = try container.decodeArrayIfPresentIgnoringFailures([UserPayload].self, forKey: .mentionedUsers)
        attachments = try container.decodeIfPresent([OptionalDecodable].self, forKey: .attachments)?
            .compactMap(\.base) ?? []

        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: MessagePayloadsCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }
        quotedMessageId = try container.decodeIfPresent(MessageId.self, forKey: .quotedMessageId)
        quotedMessage = try container.decodeIfPresent(MessagePayload.self, forKey: .quotedMessage)
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
