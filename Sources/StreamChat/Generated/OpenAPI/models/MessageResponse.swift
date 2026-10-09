//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents any chat message
final class MessageResponse: Sendable, Decodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]
    /// Channel unique identifier in <type>:<id> format
    let cid: String
    /// Contains provided slash command
    let command: String?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// Date/time of deletion
    let deletedAt: Date?
    let deletedForMe: Bool?
    let deletedReplyCount: Int
    let draft: DraftPayload?
    /// Object with translations. Key `language` contains the original language key. Other keys contain translations
    let i18n: [String: String]?
    /// Message ID is unique string identifier of the message
    let id: String
    /// List of 10 latest reactions to this message
    let latestReactions: [MessageReactionPayload]
    let member: MemberInfoPayload?
    /// Whether the message mentioned the channel tag
    let mentionedChannel: Bool
    /// Channel member data for the users mentioned in the message, keyed by user id. Only present when the app has member custom on mentioned users enabled, and only for the first two mentioned users of each message
    let mentionedChannelMembers: [String: MemberInfoPayload]?
    /// List of user group IDs mentioned in the message. Group members who are also channel members will receive push notifications based on their push preferences. Max 10 groups
    let mentionedGroupIds: [String]?
    /// List of mentioned user group objects.
    let mentionedGroups: [UserGroup]?
    /// Whether the message mentioned online users with @here tag
    let mentionedHere: Bool
    /// List of roles mentioned in the message (e.g. admin, channel_moderator, custom roles). Members with matching roles will receive push notifications based on their push preferences. Max 10 roles
    let mentionedRoles: [String]?
    /// List of mentioned users
    let mentionedUsers: [UserPayload]
    let messageTextUpdatedAt: Date?
    let moderation: MessageModerationDetailsPayload?
    /// List of 10 latest reactions of authenticated user to this message
    let ownReactions: [MessageReactionPayload]
    /// ID of parent message (thread)
    let parentId: String?
    /// Date when pinned message expires
    let pinExpires: Date?
    /// Whether message is pinned or not
    let pinned: Bool
    /// Date when message got pinned
    let pinnedAt: Date?
    /// User response object
    let pinnedBy: UserPayload?
    let poll: PollPayload?
    /// Identifier of the poll to include in the message
    let pollId: String?
    /// Represents any chat message
    let quotedMessage: MessageResponse?
    let quotedMessageId: String?
    /// An object containing number of reactions of each type. Key: reaction type (string), value: number of reactions (int)
    let reactionCounts: [String: Int]
    let reactionGroups: [String: MessageReactionGroupPayload?]?
    /// An object containing scores of reactions of each type. Key: reaction type (string), value: total score of reactions (int)
    let reactionScores: [String: Int]
    let reminder: ReminderPayload?
    /// Number of replies to this message
    let replyCount: Int
    /// A list of user ids that have restricted visibility to the message, if the list is not empty, the message is only visible to the users in the list
    let restrictedVisibility: [String]
    /// Whether the message was shadowed or not
    let shadowed: Bool
    let sharedLocation: SharedLocation?
    /// Whether thread reply should be shown in the channel as well
    let showInChannel: Bool?
    /// Whether message is silent or not
    let silent: Bool
    /// Text of the message. Should be empty if `mml` is provided
    let text: String
    /// List of users who participate in thread
    let threadParticipants: [UserPayload]?
    /// Contains type of the message. One of: regular, ephemeral, error, reply, system, deleted
    let type: String
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload

    init(
        attachments: [MessageAttachmentPayload],
        cid: String,
        command: String? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        deletedForMe: Bool? = nil,
        deletedReplyCount: Int,
        draft: DraftPayload? = nil,
        i18n: [String: String]? = nil,
        id: String,
        latestReactions: [MessageReactionPayload],
        member: MemberInfoPayload? = nil,
        mentionedChannel: Bool,
        mentionedChannelMembers: [String: MemberInfoPayload]? = nil,
        mentionedGroupIds: [String]? = nil,
        mentionedGroups: [UserGroup]? = nil,
        mentionedHere: Bool,
        mentionedRoles: [String]? = nil,
        mentionedUsers: [UserPayload],
        messageTextUpdatedAt: Date? = nil,
        moderation: MessageModerationDetailsPayload? = nil,
        ownReactions: [MessageReactionPayload],
        parentId: String? = nil,
        pinExpires: Date? = nil,
        pinned: Bool,
        pinnedAt: Date? = nil,
        pinnedBy: UserPayload? = nil,
        poll: PollPayload? = nil,
        pollId: String? = nil,
        quotedMessage: MessageResponse? = nil,
        quotedMessageId: String? = nil,
        reactionCounts: [String: Int],
        reactionGroups: [String: MessageReactionGroupPayload?]? = nil,
        reactionScores: [String: Int],
        reminder: ReminderPayload? = nil,
        replyCount: Int,
        restrictedVisibility: [String],
        shadowed: Bool,
        sharedLocation: SharedLocation? = nil,
        showInChannel: Bool? = nil,
        silent: Bool,
        text: String,
        threadParticipants: [UserPayload]? = nil,
        type: String,
        updatedAt: Date,
        user: UserPayload
    ) {
        self.attachments = attachments
        self.cid = cid
        self.command = command
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.deletedForMe = deletedForMe
        self.deletedReplyCount = deletedReplyCount
        self.draft = draft
        self.i18n = i18n
        self.id = id
        self.latestReactions = latestReactions
        self.member = member
        self.mentionedChannel = mentionedChannel
        self.mentionedChannelMembers = mentionedChannelMembers
        self.mentionedGroupIds = mentionedGroupIds
        self.mentionedGroups = mentionedGroups
        self.mentionedHere = mentionedHere
        self.mentionedRoles = mentionedRoles
        self.mentionedUsers = mentionedUsers
        self.messageTextUpdatedAt = messageTextUpdatedAt
        self.moderation = moderation
        self.ownReactions = ownReactions
        self.parentId = parentId
        self.pinExpires = pinExpires
        self.pinned = pinned
        self.pinnedAt = pinnedAt
        self.pinnedBy = pinnedBy
        self.poll = poll
        self.pollId = pollId
        self.quotedMessage = quotedMessage
        self.quotedMessageId = quotedMessageId
        self.reactionCounts = reactionCounts
        self.reactionGroups = reactionGroups
        self.reactionScores = reactionScores
        self.reminder = reminder
        self.replyCount = replyCount
        self.restrictedVisibility = restrictedVisibility
        self.shadowed = shadowed
        self.sharedLocation = sharedLocation
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
        self.threadParticipants = threadParticipants
        self.type = type
        self.updatedAt = updatedAt
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.attachments = try container.decodeArrayIgnoringFailures(
            [MessageAttachmentPayload].self,
            forKey: .attachments
        )
        self.cid = try container.decode(String.self, forKey: .cid)
        self.command = try container.decodeIfPresent(String.self, forKey: .command)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        self.deletedForMe = try container.decodeIfPresent(Bool.self, forKey: .deletedForMe)
        self.deletedReplyCount = try container.decode(Int.self, forKey: .deletedReplyCount)
        self.draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        self.i18n = try container.decodeIfPresent([String: String].self, forKey: .i18n)
        self.id = try container.decode(String.self, forKey: .id)
        self.latestReactions = try container.decodeArrayIgnoringFailures(
            [MessageReactionPayload].self,
            forKey: .latestReactions
        )
        self.member = try container.decodeIfPresent(MemberInfoPayload.self, forKey: .member)
        self.mentionedChannel = try container.decodeIfPresent(Bool.self, forKey: .mentionedChannel) ?? false
        self.mentionedChannelMembers = try container.decodeIfPresent(
            [String: MemberInfoPayload].self,
            forKey: .mentionedChannelMembers
        )
        self.mentionedGroupIds = try container.decodeIfPresent(
            [String].self,
            forKey: .mentionedGroupIds
        )
        self.mentionedGroups = try container.decodeArrayIfPresentIgnoringFailures(
            [UserGroup].self,
            forKey: .mentionedGroups
        )
        self.mentionedHere = try container.decodeIfPresent(Bool.self, forKey: .mentionedHere) ?? false
        self.mentionedRoles = try container.decodeIfPresent([String].self, forKey: .mentionedRoles)
        self.mentionedUsers = try container.decodeArrayIgnoringFailures(
            [UserPayload].self,
            forKey: .mentionedUsers
        )
        self.messageTextUpdatedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .messageTextUpdatedAt
        )
        self.moderation = try container.decodeIfPresent(
            MessageModerationDetailsPayload.self,
            forKey: .moderation
        )
        self.ownReactions = try container.decodeArrayIgnoringFailures(
            [MessageReactionPayload].self,
            forKey: .ownReactions
        )
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        self.pinExpires = try container.decodeIfPresent(Date.self, forKey: .pinExpires)
        self.pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        self.pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        self.pinnedBy = try container.decodeIfPresent(UserPayload.self, forKey: .pinnedBy)
        self.poll = try container.decodeIfPresent(PollPayload.self, forKey: .poll)
        self.pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        self.quotedMessage = try container.decodeIfPresent(
            MessageResponse.self,
            forKey: .quotedMessage
        )
        self.quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        self.reactionCounts = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .reactionCounts
        ) ?? [:]
        self.reactionGroups = try container.decodeIfPresent(
            [String: MessageReactionGroupPayload?].self,
            forKey: .reactionGroups
        )
        self.reactionScores = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .reactionScores
        ) ?? [:]
        self.reminder = try container.decodeIfPresent(ReminderPayload.self, forKey: .reminder)
        self.replyCount = try container.decode(Int.self, forKey: .replyCount)
        self.restrictedVisibility = try container.decodeIfPresent(
            [String].self,
            forKey: .restrictedVisibility
        ) ?? []
        self.shadowed = try container.decodeIfPresent(Bool.self, forKey: .shadowed) ?? false
        self.sharedLocation = try container.decodeIfPresent(
            SharedLocation.self,
            forKey: .sharedLocation
        )
        self.showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        self.silent = try container.decodeIfPresent(Bool.self, forKey: .silent) ?? false
        self.text = try container.decode(String.self, forKey: .text)
        self.threadParticipants = try container.decodeArrayIfPresentIgnoringFailures(
            [UserPayload].self,
            forKey: .threadParticipants
        )
        self.type = try container.decode(String.self, forKey: .type)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
