//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The message a scheduled message will send
final class ScheduledMessageContentResponse: Sendable, Decodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]?
    let custom: [String: RawJSON]
    /// Contains HTML markup of the message
    let html: String?
    /// Whether the message mentions the whole channel
    let mentionedChannel: Bool?
    /// IDs of the user groups mentioned in the message
    let mentionedGroupIds: [String]?
    /// Whether the message mentions the online channel members
    let mentionedHere: Bool?
    /// Roles mentioned in the message
    let mentionedRoles: [String]?
    /// IDs of the users mentioned in the message
    let mentionedUsers: [String]?
    /// MML content of the message
    let mml: String?
    /// ID of parent message (thread)
    let parentId: String?
    /// Date/time the pin expires
    let pinExpires: Date?
    /// Whether the message will be pinned when sent
    let pinned: Bool?
    /// Identifier of the poll to include in the message
    let pollId: String?
    let quotedMessageId: String?
    /// IDs of the users the message will be visible to
    let restrictedVisibility: [String]?
    /// The location a scheduled message will share
    let sharedLocation: ScheduledMessageLocation?
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
        mentionedChannel: Bool? = nil,
        mentionedGroupIds: [String]? = nil,
        mentionedHere: Bool? = nil,
        mentionedRoles: [String]? = nil,
        mentionedUsers: [String]? = nil,
        mml: String? = nil,
        parentId: String? = nil,
        pinExpires: Date? = nil,
        pinned: Bool? = nil,
        pollId: String? = nil,
        quotedMessageId: String? = nil,
        restrictedVisibility: [String]? = nil,
        sharedLocation: ScheduledMessageLocation? = nil,
        showInChannel: Bool? = nil,
        silent: Bool? = nil,
        text: String,
        type: String? = nil
    ) {
        self.attachments = attachments
        self.custom = custom
        self.html = html
        self.mentionedChannel = mentionedChannel
        self.mentionedGroupIds = mentionedGroupIds
        self.mentionedHere = mentionedHere
        self.mentionedRoles = mentionedRoles
        self.mentionedUsers = mentionedUsers
        self.mml = mml
        self.parentId = parentId
        self.pinExpires = pinExpires
        self.pinned = pinned
        self.pollId = pollId
        self.quotedMessageId = quotedMessageId
        self.restrictedVisibility = restrictedVisibility
        self.sharedLocation = sharedLocation
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
        self.html = try container.decodeIfPresent(String.self, forKey: .html)
        self.mentionedChannel = try container.decodeIfPresent(Bool.self, forKey: .mentionedChannel)
        self.mentionedGroupIds = try container.decodeIfPresent(
            [String].self,
            forKey: .mentionedGroupIds
        )
        self.mentionedHere = try container.decodeIfPresent(Bool.self, forKey: .mentionedHere)
        self.mentionedRoles = try container.decodeIfPresent([String].self, forKey: .mentionedRoles)
        self.mentionedUsers = try container.decodeIfPresent([String].self, forKey: .mentionedUsers)
        self.mml = try container.decodeIfPresent(String.self, forKey: .mml)
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        self.pinExpires = try container.decodeIfPresent(Date.self, forKey: .pinExpires)
        self.pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)
        self.pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        self.quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        self.restrictedVisibility = try container.decodeIfPresent(
            [String].self,
            forKey: .restrictedVisibility
        )
        self.sharedLocation = try container.decodeIfPresent(
            ScheduledMessageLocation.self,
            forKey: .sharedLocation
        )
        self.showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        self.silent = try container.decodeIfPresent(Bool.self, forKey: .silent)
        self.text = try container.decode(String.self, forKey: .text)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
