//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResultMessage: Sendable, Decodable {
    let attachments: [MessageAttachmentPayload]
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let cid: String
    let command: String?
    let createdAt: Date
    let custom: [String: RawJSON]
    let deletedAt: Date?
    let deletedForMe: Bool?
    let deletedReplyCount: Int
    let draft: DraftPayload?
    let i18n: [String: String]?
    let id: String
    let latestReactions: [MessageReactionPayload]
    let member: MemberInfoPayload?
    let mentionedChannel: Bool
    let mentionedChannelMembers: [String: MemberInfoPayload]?
    let mentionedGroupIds: [String]?
    let mentionedGroups: [UserGroup]?
    let mentionedHere: Bool
    let mentionedRoles: [String]?
    let mentionedUsers: [UserPayload]
    let messageTextUpdatedAt: Date?
    let moderation: MessageModerationDetailsPayload?
    let ownReactions: [MessageReactionPayload]
    let parentId: String?
    let pinExpires: Date?
    let pinned: Bool
    let pinnedAt: Date?
    /// User response object
    let pinnedBy: UserPayload?
    let poll: PollPayload?
    let pollId: String?
    /// Represents any chat message
    let quotedMessage: MessageResponse?
    let quotedMessageId: String?
    let reactionCounts: [String: Int]
    let reactionGroups: [String: MessageReactionGroupPayload?]?
    let reactionScores: [String: Int]
    let reminder: ReminderPayload?
    let replyCount: Int
    let restrictedVisibility: [String]
    let shadowed: Bool
    let sharedLocation: SharedLocation?
    let showInChannel: Bool?
    let silent: Bool
    let text: String
    let threadParticipants: [UserPayload]?
    let type: String
    let updatedAt: Date
    /// User response object
    let user: UserPayload

    init(
        attachments: [MessageAttachmentPayload],
        channel: ChannelDetailPayload? = nil,
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
        self.channel = channel
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
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(String.self, forKey: .cid)
        self.command = try container.decodeIfPresent(String.self, forKey: .command)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
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
        self.mentionedChannel = try container.decode(Bool.self, forKey: .mentionedChannel)
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
        self.mentionedHere = try container.decode(Bool.self, forKey: .mentionedHere)
        self.mentionedRoles = try container.decodeArrayIfPresentIgnoringFailures(
            [String].self,
            forKey: .mentionedRoles
        )
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
        self.pinned = try container.decode(Bool.self, forKey: .pinned)
        self.pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        self.pinnedBy = try container.decodeIfPresent(UserPayload.self, forKey: .pinnedBy)
        self.poll = try container.decodeIfPresent(PollPayload.self, forKey: .poll)
        self.pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        self.quotedMessage = try container.decodeIfPresent(
            MessageResponse.self,
            forKey: .quotedMessage
        )
        self.quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        self.reactionCounts = try container.decode([String: Int].self, forKey: .reactionCounts)
        self.reactionGroups = try container.decodeIfPresent(
            [String: MessageReactionGroupPayload?].self,
            forKey: .reactionGroups
        )
        self.reactionScores = try container.decode([String: Int].self, forKey: .reactionScores)
        self.reminder = try container.decodeIfPresent(ReminderPayload.self, forKey: .reminder)
        self.replyCount = try container.decode(Int.self, forKey: .replyCount)
        self.restrictedVisibility = try container.decodeArrayIgnoringFailures(
            [String].self,
            forKey: .restrictedVisibility
        )
        self.shadowed = try container.decode(Bool.self, forKey: .shadowed)
        self.sharedLocation = try container.decodeIfPresent(
            SharedLocation.self,
            forKey: .sharedLocation
        )
        self.showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        self.silent = try container.decode(Bool.self, forKey: .silent)
        self.text = try container.decode(String.self, forKey: .text)
        self.threadParticipants = try container.decodeIfPresent(
            [UserPayload].self,
            forKey: .threadParticipants
        )
        self.type = try container.decode(String.self, forKey: .type)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
