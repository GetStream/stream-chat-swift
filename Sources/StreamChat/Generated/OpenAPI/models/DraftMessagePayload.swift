//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

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

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attachments = try container.decodeIfPresent(
            [MessageAttachmentPayload].self,
            forKey: .attachments
        )
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        html = try container.decodeIfPresent(String.self, forKey: .html)
        id = try container.decode(String.self, forKey: .id)
        mentionedUsers = try container.decodeIfPresent([UserPayload].self, forKey: .mentionedUsers)
        mml = try container.decodeIfPresent(String.self, forKey: .mml)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        silent = try container.decodeIfPresent(Bool.self, forKey: .silent)
        text = try container.decode(String.self, forKey: .text)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
