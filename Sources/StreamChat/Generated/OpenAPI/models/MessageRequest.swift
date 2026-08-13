//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageRequest: Sendable, Codable, JSONEncodable {
    enum MessageRequestType: String, Sendable, Codable, CaseIterable {
        case regular
        case system
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

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
    /// Should be empty if `text` is provided. Can only be set when using server-side API
    let mml: String?
    /// ID of parent message (thread)
    let parentId: String?
    /// Date when pinned message expires
    let pinExpires: Date?
    /// Whether message is pinned or not
    let pinned: Bool?
    /// Date when message got pinned
    let pinnedAt: Date?
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
        mml: String? = nil,
        parentId: String? = nil,
        pinExpires: Date? = nil,
        pinned: Bool? = nil,
        pinnedAt: Date? = nil,
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
        self.mml = mml
        self.parentId = parentId
        self.pinExpires = pinExpires
        self.pinned = pinned
        self.pinnedAt = pinnedAt
        self.pollId = pollId
        self.quotedMessageId = quotedMessageId
        self.restrictedVisibility = restrictedVisibility
        self.sharedLocation = sharedLocation
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case custom
        case id
        case mentionedChannel = "mentioned_channel"
        case mentionedGroupIds = "mentioned_group_ids"
        case mentionedHere = "mentioned_here"
        case mentionedRoles = "mentioned_roles"
        case mentionedUsers = "mentioned_users"
        case mml
        case parentId = "parent_id"
        case pinExpires = "pin_expires"
        case pinned
        case pinnedAt = "pinned_at"
        case pollId = "poll_id"
        case quotedMessageId = "quoted_message_id"
        case restrictedVisibility = "restricted_visibility"
        case sharedLocation = "shared_location"
        case showInChannel = "show_in_channel"
        case silent
        case text
        case type
    }
}
