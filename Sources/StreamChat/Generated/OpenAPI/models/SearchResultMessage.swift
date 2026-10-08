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
        attachments = try container.decodeArrayIgnoringFailures(
            [MessageAttachmentPayload].self,
            forKey: .attachments
        )
        channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        cid = try container.decode(String.self, forKey: .cid)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        deletedForMe = try container.decodeIfPresent(Bool.self, forKey: .deletedForMe)
        deletedReplyCount = try container.decode(Int.self, forKey: .deletedReplyCount)
        draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        i18n = try container.decodeIfPresent([String: String].self, forKey: .i18n)
        id = try container.decode(String.self, forKey: .id)
        latestReactions = try container.decodeArrayIgnoringFailures(
            [MessageReactionPayload].self,
            forKey: .latestReactions
        )
        member = try container.decodeIfPresent(MemberInfoPayload.self, forKey: .member)
        mentionedChannel = try container.decodeIfPresent(Bool.self, forKey: .mentionedChannel) ?? false
        mentionedChannelMembers = try container.decodeIfPresent(
            [String: MemberInfoPayload].self,
            forKey: .mentionedChannelMembers
        )
        mentionedGroupIds = try container.decodeIfPresent([String].self, forKey: .mentionedGroupIds)
        mentionedGroups = try container.decodeArrayIfPresentIgnoringFailures(
            [UserGroup].self,
            forKey: .mentionedGroups
        )
        mentionedHere = try container.decodeIfPresent(Bool.self, forKey: .mentionedHere) ?? false
        mentionedRoles = try container.decodeArrayIfPresentIgnoringFailures(
            [String].self,
            forKey: .mentionedRoles
        )
        mentionedUsers = try container.decodeArrayIgnoringFailures(
            [UserPayload].self,
            forKey: .mentionedUsers
        )
        messageTextUpdatedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .messageTextUpdatedAt
        )
        moderation = try container.decodeIfPresent(
            MessageModerationDetailsPayload.self,
            forKey: .moderation
        )
        ownReactions = try container.decodeArrayIgnoringFailures(
            [MessageReactionPayload].self,
            forKey: .ownReactions
        )
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        pinExpires = try container.decodeIfPresent(Date.self, forKey: .pinExpires)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        pinnedBy = try container.decodeIfPresent(UserPayload.self, forKey: .pinnedBy)
        poll = try container.decodeIfPresent(PollPayload.self, forKey: .poll)
        pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        quotedMessage = try container.decodeIfPresent(MessageResponse.self, forKey: .quotedMessage)
        quotedMessageId = try container.decodeIfPresent(String.self, forKey: .quotedMessageId)
        reactionCounts = try container.decodeIfPresent([String: Int].self, forKey: .reactionCounts) ?? [:]
        reactionGroups = try container.decodeIfPresent(
            [String: MessageReactionGroupPayload?].self,
            forKey: .reactionGroups
        )
        reactionScores = try container.decodeIfPresent([String: Int].self, forKey: .reactionScores) ?? [:]
        reminder = try container.decodeIfPresent(ReminderPayload.self, forKey: .reminder)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        restrictedVisibility = try container.decodeArrayIfPresentIgnoringFailures(
            [String].self,
            forKey: .restrictedVisibility
        ) ?? []
        shadowed = try container.decodeIfPresent(Bool.self, forKey: .shadowed) ?? false
        sharedLocation = try container.decodeIfPresent(SharedLocation.self, forKey: .sharedLocation)
        showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        silent = try container.decodeIfPresent(Bool.self, forKey: .silent) ?? false
        text = try container.decode(String.self, forKey: .text)
        threadParticipants = try container.decodeIfPresent(
            [UserPayload].self,
            forKey: .threadParticipants
        )
        type = try container.decode(String.self, forKey: .type)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        user = try container.decode(UserPayload.self, forKey: .user)
    }
}
