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
    let html: String
    let i18n: [String: String]?
    let id: String
    let imageLabels: [String: [String]]?
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
    let mml: String?
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
        html: String,
        i18n: [String: String]? = nil,
        id: String,
        imageLabels: [String: [String]]? = nil,
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
        mml: String? = nil,
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
        self.html = html
        self.i18n = i18n
        self.id = id
        self.imageLabels = imageLabels
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
        self.mml = mml
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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case channel
        case cid
        case command
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case deletedForMe = "deleted_for_me"
        case deletedReplyCount = "deleted_reply_count"
        case draft
        case html
        case i18n
        case id
        case imageLabels = "image_labels"
        case latestReactions = "latest_reactions"
        case member
        case mentionedChannel = "mentioned_channel"
        case mentionedChannelMembers = "mentioned_channel_members"
        case mentionedGroupIds = "mentioned_group_ids"
        case mentionedGroups = "mentioned_groups"
        case mentionedHere = "mentioned_here"
        case mentionedRoles = "mentioned_roles"
        case mentionedUsers = "mentioned_users"
        case messageTextUpdatedAt = "message_text_updated_at"
        case mml
        case moderation
        case ownReactions = "own_reactions"
        case parentId = "parent_id"
        case pinExpires = "pin_expires"
        case pinned
        case pinnedAt = "pinned_at"
        case pinnedBy = "pinned_by"
        case poll
        case pollId = "poll_id"
        case quotedMessage = "quoted_message"
        case quotedMessageId = "quoted_message_id"
        case reactionCounts = "reaction_counts"
        case reactionGroups = "reaction_groups"
        case reactionScores = "reaction_scores"
        case reminder
        case replyCount = "reply_count"
        case restrictedVisibility = "restricted_visibility"
        case shadowed
        case sharedLocation = "shared_location"
        case showInChannel = "show_in_channel"
        case silent
        case text
        case threadParticipants = "thread_participants"
        case type
        case updatedAt = "updated_at"
        case user
    }
}
