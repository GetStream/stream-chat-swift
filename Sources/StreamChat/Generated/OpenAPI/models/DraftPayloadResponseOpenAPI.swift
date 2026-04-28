//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftPayloadResponseOpenAPI: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// [RawJSON] of message attachments
    var attachments: [Attachment]?
    var custom: [String: RawJSON]
    /// Contains HTML markup of the message
    var html: String?
    /// Message ID is unique string identifier of the message
    var id: String
    /// List of mentioned users
    var mentionedUsers: [UserResponse]?
    /// MML content of the message
    var mml: String?
    /// ID of parent message (thread)
    var parentId: String?
    /// Identifier of the poll to include in the message
    var pollId: String?
    var quotedMessageId: String?
    /// Whether thread reply should be shown in the channel as well
    var showInChannel: Bool?
    /// Whether message is silent or not
    var silent: Bool?
    /// Text of the message
    var text: String
    /// Contains type of the message. One of: regular, system
    var type: String?

    init(attachments: [Attachment]? = nil, custom: [String: RawJSON], html: String? = nil, id: String, mentionedUsers: [UserResponse]? = nil, mml: String? = nil, parentId: String? = nil, pollId: String? = nil, quotedMessageId: String? = nil, showInChannel: Bool? = nil, silent: Bool? = nil, text: String) {
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

    static func == (lhs: DraftPayloadResponseOpenAPI, rhs: DraftPayloadResponseOpenAPI) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.custom == rhs.custom &&
            lhs.html == rhs.html &&
            lhs.id == rhs.id &&
            lhs.mentionedUsers == rhs.mentionedUsers &&
            lhs.mml == rhs.mml &&
            lhs.parentId == rhs.parentId &&
            lhs.pollId == rhs.pollId &&
            lhs.quotedMessageId == rhs.quotedMessageId &&
            lhs.showInChannel == rhs.showInChannel &&
            lhs.silent == rhs.silent &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(custom)
        hasher.combine(html)
        hasher.combine(id)
        hasher.combine(mentionedUsers)
        hasher.combine(mml)
        hasher.combine(parentId)
        hasher.combine(pollId)
        hasher.combine(quotedMessageId)
        hasher.combine(showInChannel)
        hasher.combine(silent)
        hasher.combine(text)
        hasher.combine(type)
    }
}
