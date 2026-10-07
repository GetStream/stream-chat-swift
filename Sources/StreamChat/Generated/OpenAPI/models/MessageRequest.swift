//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageRequestType: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let regular = MessageRequestType(rawValue: "regular")
    static let system = MessageRequestType(rawValue: "system")
}

/// Message data for creating or updating a message
final class MessageRequest: Sendable, Encodable, JSONEncodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]?
    let custom: [String: RawJSON]?
    /// Message ID is unique string identifier of the message
    let id: String?
    let mentionedChannel: Bool?
    /// List of user group IDs to mention. Group members who are also channel members will receive push notifications. Max 10 groups
    let mentionedGroupIds: [String]?
    let mentionedHere: Bool?
    let mentionedRoles: [String]?
    /// Array of user IDs to mention
    let mentionedUsers: [String]?
    /// ID of parent message (thread)
    let parentId: String?
    /// Date when pinned message expires
    let pinExpires: Date?
    /// Whether message is pinned or not
    let pinned: Bool?
    /// Identifier of the poll to include in the message
    let pollId: String?
    let quotedMessageId: String?
    /// A list of user ids that have restricted visibility to the message
    let restrictedVisibility: [String]?
    let sharedLocation: NewLocationRequestPayload?
    /// Whether thread reply should be shown in the channel as well
    let showInChannel: Bool?
    /// Whether message is silent or not
    let silent: Bool?
    /// Text of the message. Should be empty if `mml` is provided
    let text: String?
    /// Contains type of the message. One of: regular, system
    let type: MessageRequestType?

    init(
        attachments: [MessageAttachmentPayload]? = nil,
        custom: [String: RawJSON]? = nil,
        id: String? = nil,
        mentionedChannel: Bool? = nil,
        mentionedGroupIds: [String]? = nil,
        mentionedHere: Bool? = nil,
        mentionedRoles: [String]? = nil,
        mentionedUsers: [String]? = nil,
        parentId: String? = nil,
        pinExpires: Date? = nil,
        pinned: Bool? = nil,
        pollId: String? = nil,
        quotedMessageId: String? = nil,
        restrictedVisibility: [String]? = nil,
        sharedLocation: NewLocationRequestPayload? = nil,
        showInChannel: Bool? = nil,
        silent: Bool? = nil,
        text: String? = nil,
        type: MessageRequestType? = nil
    ) {
        self.attachments = attachments
        self.custom = custom
        self.id = id
        self.mentionedChannel = mentionedChannel
        self.mentionedGroupIds = mentionedGroupIds
        self.mentionedHere = mentionedHere
        self.mentionedRoles = mentionedRoles
        self.mentionedUsers = mentionedUsers
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(attachments, forKey: .attachments)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(mentionedChannel, forKey: .mentionedChannel)
        try container.encodeIfPresent(mentionedGroupIds, forKey: .mentionedGroupIds)
        try container.encodeIfPresent(mentionedHere, forKey: .mentionedHere)
        try container.encodeIfPresent(mentionedRoles, forKey: .mentionedRoles)
        try container.encodeIfPresent(mentionedUsers, forKey: .mentionedUsers)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encodeIfPresent(pinExpires, forKey: .pinExpires)
        try container.encodeIfPresent(pinned, forKey: .pinned)
        try container.encodeIfPresent(pollId, forKey: .pollId)
        try container.encodeIfPresent(quotedMessageId, forKey: .quotedMessageId)
        try container.encodeIfPresent(restrictedVisibility, forKey: .restrictedVisibility)
        try container.encodeIfPresent(sharedLocation, forKey: .sharedLocation)
        try container.encodeIfPresent(showInChannel, forKey: .showInChannel)
        try container.encodeIfPresent(silent, forKey: .silent)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(type, forKey: .type)
    }
}
