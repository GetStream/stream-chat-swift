//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The message a scheduled message will send
final class ScheduledMessageContentResponse: Sendable, Decodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]?
    let custom: [String: RawJSON]
    /// IDs of the users mentioned in the message
    let mentionedUsers: [String]?
    /// ID of parent message (thread)
    let parentId: String?
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
        mentionedUsers: [String]? = nil,
        parentId: String? = nil,
        quotedMessageId: String? = nil,
        showInChannel: Bool? = nil,
        silent: Bool? = nil,
        text: String,
        type: String? = nil
    ) {
        self.attachments = attachments
        self.custom = custom
        self.mentionedUsers = mentionedUsers
        self.parentId = parentId
        self.quotedMessageId = quotedMessageId
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.attachments = try container.decodeIfPresent(
            [MessageAttachmentPayload].self,
            forKey: .attachments
        )
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.mentionedUsers = try container.decodeIfPresent([String].self, forKey: .mentionedUsers)
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        self.quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        self.showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        self.silent = try container.decodeIfPresent(Bool.self, forKey: .silent)
        self.text = try container.decode(String.self, forKey: .text)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
