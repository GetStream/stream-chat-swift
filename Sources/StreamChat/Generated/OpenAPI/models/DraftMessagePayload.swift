//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftMessagePayload: Sendable, Decodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]?
    let custom: [String: RawJSON]
    /// Contains HTML markup of the message
    let html: String?
    /// Message ID is unique string identifier of the message
    let id: String
    /// List of mentioned users
    let mentionedUsers: [UserPayload]?
    /// MML content of the message
    let mml: String?
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
        html: String? = nil,
        id: String,
        mentionedUsers: [UserPayload]? = nil,
        mml: String? = nil,
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
        self.html = html
        self.id = id
        self.mentionedUsers = mentionedUsers
        self.mml = mml
        self.parentId = parentId
        self.pollId = pollId
        self.quotedMessageId = quotedMessageId
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case custom
        case html
        case id
        case mentionedUsers = "mentioned_users"
        case mml
        case parentId = "parent_id"
        case pollId = "poll_id"
        case quotedMessageId = "quoted_message_id"
        case showInChannel = "show_in_channel"
        case silent
        case text
        case type
    }
}
