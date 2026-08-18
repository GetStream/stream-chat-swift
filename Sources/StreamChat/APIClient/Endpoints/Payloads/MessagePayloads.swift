//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coding keys for message-related JSON payloads
enum MessagePayloadsCodingKeys: String, CodingKey, CaseIterable {
    case id
    case cid
    case channelId = "channel_cid"
    case type
    case user
    case userId = "user_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deletedAt = "deleted_at"
    case text
    case command
    case args
    case attachments
    case parentId = "parent_id"
    case showReplyInChannel = "show_in_channel"
    case quotedMessageId = "quoted_message_id"
    case quotedMessage = "quoted_message"
    case parentMessage = "parent_message"
    case mentionedUsers = "mentioned_users"
    case mentionedHere = "mentioned_here"
    case mentionedChannel = "mentioned_channel"
    case mentionedGroupIds = "mentioned_group_ids"
    case mentionedGroups = "mentioned_groups"
    case mentionedRoles = "mentioned_roles"
    case threadParticipants = "thread_participants"
    case replyCount = "reply_count"
    case latestReactions = "latest_reactions"
    case ownReactions = "own_reactions"
    case reactionScores = "reaction_scores"
    case reactionCounts = "reaction_counts"
    case reactionGroups = "reaction_groups"
    case isSilent = "silent"
    case channel
    case pinned
    case pinnedBy = "pinned_by"
    case pinnedAt = "pinned_at"
    case pinExpires = "pin_expires"
    case html
    case i18n
    case mml
    case imageLabels = "image_labels"
    case shadowed
    case moderationDetails = "moderation_details" // moderation v1 key
    case moderation // moderation v2 key
    case messageTextUpdatedAt = "message_text_updated_at"
    case message
    case poll
    case pollId = "poll_id"
    case set
    case unset
    case skipEnrichUrl = "skip_enrich_url"
    case restrictedVisibility = "restricted_visibility"
    case draft
    case location = "shared_location"
    case reminder
    case member
    case deletedForMe = "deleted_for_me"
}

extension MessagePayload {
    /// A object describing the incoming JSON format for message payload. Unfortunately, our backend is not consistent
    /// in this and the payload has the form: `{ "message": <message payload> }` rather than `{ <message payload> }`
    struct Boxed: Decodable {
        let message: MessagePayload
    }
}

struct MessageSearchResultsPayload: Decodable {
    let results: [MessagePayload.Boxed]
    let next: String?
}

/// An object describing the outgoing message JSON payload.
struct MessageRequestBody: Encodable, Sendable {
    let id: String
    let user: UserRequestBody
    let text: String

    // Used at the moment only for creating a system a message.
    let type: String?

    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let isSilent: Bool
    let quotedMessageId: String?
    let attachments: [MessageAttachmentPayload]
    let mentionedUserIds: [UserId]
    let mentionedHere: Bool
    let mentionedChannel: Bool
    let mentionedGroupIds: [String]
    let mentionedRoles: [String]
    var pinned: Bool
    var pinExpires: Date?
    var pollId: String?
    var location: NewLocationRequestPayload?
    var restrictedVisibility: [UserId]?
    let extraData: [String: RawJSON]

    init(
        id: String,
        user: UserRequestBody,
        text: String,
        type: String? = nil,
        command: String? = nil,
        args: String? = nil,
        parentId: String? = nil,
        showReplyInChannel: Bool = false,
        isSilent: Bool = false,
        quotedMessageId: String? = nil,
        attachments: [MessageAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        mentionedHere: Bool = false,
        mentionedChannel: Bool = false,
        mentionedGroupIds: [String] = [],
        mentionedRoles: [String] = [],
        pinned: Bool = false,
        pinExpires: Date? = nil,
        pollId: String? = nil,
        restrictedVisibility: [UserId]? = nil,
        location: NewLocationRequestPayload? = nil,
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.user = user
        self.text = text
        self.type = type
        self.command = command
        self.args = args
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        self.isSilent = isSilent
        self.quotedMessageId = quotedMessageId
        self.attachments = attachments
        self.mentionedUserIds = mentionedUserIds
        self.mentionedHere = mentionedHere
        self.mentionedChannel = mentionedChannel
        self.mentionedGroupIds = mentionedGroupIds
        self.mentionedRoles = mentionedRoles
        self.pinned = pinned
        self.pinExpires = pinExpires
        self.pollId = pollId
        self.restrictedVisibility = restrictedVisibility
        self.location = location
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
        try container.encode(pinned, forKey: .pinned)
        try container.encodeIfPresent(pinExpires, forKey: .pinExpires)
        try container.encode(isSilent, forKey: .isSilent)
        try container.encodeIfPresent(pollId, forKey: .pollId)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(restrictedVisibility, forKey: .restrictedVisibility)
        try container.encodeIfPresent(location, forKey: .location)

        if !attachments.isEmpty {
            try container.encode(attachments, forKey: .attachments)
        }

        if !mentionedUserIds.isEmpty {
            try container.encode(mentionedUserIds, forKey: .mentionedUsers)
        }

        if mentionedHere {
            try container.encode(mentionedHere, forKey: .mentionedHere)
        }

        if mentionedChannel {
            try container.encode(mentionedChannel, forKey: .mentionedChannel)
        }

        if !mentionedGroupIds.isEmpty {
            try container.encode(mentionedGroupIds, forKey: .mentionedGroupIds)
        }

        if !mentionedRoles.isEmpty {
            try container.encode(mentionedRoles, forKey: .mentionedRoles)
        }

        try extraData.encode(to: encoder)
    }
}

/// An object describing pinned messages JSON payload.
typealias PinnedMessagesPayload = MessageListPayload

/// An object describing the message list JSON payload.
typealias MessageRepliesPayload = MessageListPayload

struct MessageListPayload: Decodable {
    let messages: [MessagePayload]
}

/// A command in a message, e.g. /giphy.
public struct Command: Codable, Hashable, Sendable {
    /// A command name.
    public let name: String
    /// A description.
    public let description: String
    public let set: String
    /// Args for the command.
    public let args: String

    public init(name: String = "", description: String = "", set: String = "", args: String = "") {
        self.name = name
        self.description = description
        self.set = set
        self.args = args
    }
}
