//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum MessageRequestType: String, Sendable, Codable, CaseIterable {
        case empty = "''"
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
    var attachments: [Attachment]?
    var custom: [String: RawJSON]?
    /// Message ID is unique string identifier of the message
    var id: String?
    var mentionedChannel: Bool?
    /// List of user group IDs to mention. Group members who are also channel members will receive push notifications. Max 10 groups
    var mentionedGroupIds: [String]?
    var mentionedHere: Bool?
    var mentionedRoles: [String]?
    /// Array of user IDs to mention
    var mentionedUsers: [String]?
    /// Should be empty if `text` is provided. Can only be set when using server-side API
    var mml: String?
    /// ID of parent message (thread)
    var parentId: String?
    /// Date when pinned message expires
    var pinExpires: Date?
    /// Whether message is pinned or not
    var pinned: Bool?
    /// Date when message got pinned
    var pinnedAt: Date?
    /// Identifier of the poll to include in the message
    var pollId: String?
    var quotedMessageId: String?
    /// A list of user ids that have restricted visibility to the message
    var restrictedVisibility: [String]?
    var sharedLocation: SharedLocationModel?
    /// Whether thread reply should be shown in the channel as well
    var showInChannel: Bool?
    /// Whether message is silent or not
    var silent: Bool?
    /// Text of the message. Should be empty if `mml` is provided
    var text: String?
    /// Contains type of the message. One of: regular, system
    var type: MessageRequestType?

    init(attachments: [Attachment]? = nil, custom: [String: RawJSON]? = nil, id: String? = nil, mentionedChannel: Bool? = nil, mentionedGroupIds: [String]? = nil, mentionedHere: Bool? = nil, mentionedRoles: [String]? = nil, mentionedUsers: [String]? = nil, mml: String? = nil, parentId: String? = nil, pinExpires: Date? = nil, pinned: Bool? = nil, pinnedAt: Date? = nil, pollId: String? = nil, quotedMessageId: String? = nil, restrictedVisibility: [String]? = nil, sharedLocation: SharedLocationModel? = nil, showInChannel: Bool? = nil, silent: Bool? = nil, text: String? = nil) {
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

    static func == (lhs: MessageRequest, rhs: MessageRequest) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.mentionedChannel == rhs.mentionedChannel &&
            lhs.mentionedGroupIds == rhs.mentionedGroupIds &&
            lhs.mentionedHere == rhs.mentionedHere &&
            lhs.mentionedRoles == rhs.mentionedRoles &&
            lhs.mentionedUsers == rhs.mentionedUsers &&
            lhs.mml == rhs.mml &&
            lhs.parentId == rhs.parentId &&
            lhs.pinExpires == rhs.pinExpires &&
            lhs.pinned == rhs.pinned &&
            lhs.pinnedAt == rhs.pinnedAt &&
            lhs.pollId == rhs.pollId &&
            lhs.quotedMessageId == rhs.quotedMessageId &&
            lhs.restrictedVisibility == rhs.restrictedVisibility &&
            lhs.sharedLocation == rhs.sharedLocation &&
            lhs.showInChannel == rhs.showInChannel &&
            lhs.silent == rhs.silent &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(mentionedChannel)
        hasher.combine(mentionedGroupIds)
        hasher.combine(mentionedHere)
        hasher.combine(mentionedRoles)
        hasher.combine(mentionedUsers)
        hasher.combine(mml)
        hasher.combine(parentId)
        hasher.combine(pinExpires)
        hasher.combine(pinned)
        hasher.combine(pinnedAt)
        hasher.combine(pollId)
        hasher.combine(quotedMessageId)
        hasher.combine(restrictedVisibility)
        hasher.combine(sharedLocation)
        hasher.combine(showInChannel)
        hasher.combine(silent)
        hasher.combine(text)
        hasher.combine(type)
    }
}
