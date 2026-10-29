//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Contains the draft message content
final class DraftMessagePayload: Sendable, Decodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]?
    let custom: [String: RawJSON]
    /// Message ID is unique string identifier of the message
    let id: String
    /// List of mentioned users
    let mentionedUsers: [UserPayload]?
    /// ID of parent message (thread)
    let parentId: String?
    /// Identifier of the poll to include in the message
    let pollId: String?
    let quotedMessageId: String?
    /// Whether thread reply should be shown in the channel as well
    let showInChannel: Bool?
    /// Whether message is silent or not
    let silent: Bool?
    /// Text of the message
    let text: String
    /// Contains type of the message. One of: regular, system
    let type: String?

    init(
        attachments: [MessageAttachmentPayload]? = nil,
        custom: [String: RawJSON],
        id: String,
        mentionedUsers: [UserPayload]? = nil,
        parentId: String? = nil,
        pollId: String? = nil,
        quotedMessageId: String? = nil,
        showInChannel: Bool? = nil,
        silent: Bool? = nil,
        text: String,
        type: String? = nil
    ) {
        self.attachments = attachments
        self.custom = custom
        self.id = id
        self.mentionedUsers = mentionedUsers
        self.parentId = parentId
        self.pollId = pollId
        self.quotedMessageId = quotedMessageId
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        attachments = try container.decodeIfPresent(
            [MessageAttachmentPayload].self,
            forKey: .attachments
        )
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        id = try container.decode(String.self, forKey: .id)
        mentionedUsers = try container.decodeIfPresent([UserPayload].self, forKey: .mentionedUsers)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        silent = try container.decodeIfPresent(Bool.self, forKey: .silent)
        text = try container.decode(String.self, forKey: .text)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
