//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageWithChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// [RawJSON] of message attachments
    var attachments: [Attachment]
    var channel: ChannelResponse
    /// Channel unique identifier in <type>:<id> format
    var cid: String
    /// Contains provided slash command
    var command: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// Date/time of deletion
    var deletedAt: Date?
    var deletedForMe: Bool?
    var deletedReplyCount: Int
    var draft: DraftResponse?
    /// Contains HTML markup of the message. Can only be set when using server-side API
    var html: String
    /// Object with translations. Key `language` contains the original language key. Other keys contain translations
    var i18n: [String: String]?
    /// Message ID is unique string identifier of the message
    var id: String
    /// Contains image moderation information
    var imageLabels: [String: [String]]?
    /// List of 10 latest reactions to this message
    var latestReactions: [ReactionResponse]
    var member: ChannelMemberResponse?
    /// Whether the message mentioned the channel tag
    var mentionedChannel: Bool
    /// List of user group IDs mentioned in the message. Group members who are also channel members will receive push notifications based on their push preferences. Max 10 groups
    var mentionedGroupIds: [String]?
    /// Whether the message mentioned online users with @here tag
    var mentionedHere: Bool
    /// List of roles mentioned in the message (e.g. admin, channel_moderator, custom roles). Members with matching roles will receive push notifications based on their push preferences. Max 10 roles
    var mentionedRoles: [String]?
    /// List of mentioned users
    var mentionedUsers: [UserResponse]
    var messageTextUpdatedAt: Date?
    /// Should be empty if `text` is provided. Can only be set when using server-side API
    var mml: String?
    var moderation: ModerationV2Response?
    /// List of 10 latest reactions of authenticated user to this message
    var ownReactions: [ReactionResponse]
    /// ID of parent message (thread)
    var parentId: String?
    /// Date when pinned message expires
    var pinExpires: Date?
    /// Whether message is pinned or not
    var pinned: Bool
    /// Date when message got pinned
    var pinnedAt: Date?
    var pinnedBy: UserResponse?
    var poll: PollResponseData?
    /// Identifier of the poll to include in the message
    var pollId: String?
    var quotedMessage: MessageResponse?
    var quotedMessageId: String?
    /// An object containing number of reactions of each type. Key: reaction type (string), value: number of reactions (int)
    var reactionCounts: [String: Int]
    var reactionGroups: [String: ReactionGroupResponse?]?
    /// An object containing scores of reactions of each type. Key: reaction type (string), value: total score of reactions (int)
    var reactionScores: [String: Int]
    var reminder: ReminderResponseData?
    /// Number of replies to this message
    var replyCount: Int
    /// A list of user ids that have restricted visibility to the message, if the list is not empty, the message is only visible to the users in the list
    var restrictedVisibility: [String]
    /// Whether the message was shadowed or not
    var shadowed: Bool
    var sharedLocation: SharedLocationResponseData?
    /// Whether thread reply should be shown in the channel as well
    var showInChannel: Bool?
    /// Whether message is silent or not
    var silent: Bool
    /// Text of the message. Should be empty if `mml` is provided
    var text: String
    /// List of users who participate in thread
    var threadParticipants: [UserResponse]?
    /// Contains type of the message. One of: regular, ephemeral, error, reply, system, deleted
    var type: String
    /// Date/time of the last update
    var updatedAt: Date
    var user: UserResponse

    init(attachments: [Attachment], channel: ChannelResponse, cid: String, command: String? = nil, createdAt: Date, custom: [String: RawJSON], deletedAt: Date? = nil, deletedForMe: Bool? = nil, deletedReplyCount: Int, draft: DraftResponse? = nil, html: String, i18n: [String: String]? = nil, id: String, imageLabels: [String: [String]]? = nil, latestReactions: [ReactionResponse], member: ChannelMemberResponse? = nil, mentionedChannel: Bool, mentionedGroupIds: [String]? = nil, mentionedHere: Bool, mentionedRoles: [String]? = nil, mentionedUsers: [UserResponse], messageTextUpdatedAt: Date? = nil, mml: String? = nil, moderation: ModerationV2Response? = nil, ownReactions: [ReactionResponse], parentId: String? = nil, pinExpires: Date? = nil, pinned: Bool, pinnedAt: Date? = nil, pinnedBy: UserResponse? = nil, poll: PollResponseData? = nil, pollId: String? = nil, quotedMessage: MessageResponse? = nil, quotedMessageId: String? = nil, reactionCounts: [String: Int], reactionGroups: [String: ReactionGroupResponse?]? = nil, reactionScores: [String: Int], reminder: ReminderResponseData? = nil, replyCount: Int, restrictedVisibility: [String], shadowed: Bool, sharedLocation: SharedLocationResponseData? = nil, showInChannel: Bool? = nil, silent: Bool, text: String, threadParticipants: [UserResponse]? = nil, type: String, updatedAt: Date, user: UserResponse) {
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
        self.mentionedGroupIds = mentionedGroupIds
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
        case mentionedGroupIds = "mentioned_group_ids"
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

    static func == (lhs: MessageWithChannelResponse, rhs: MessageWithChannelResponse) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.channel == rhs.channel &&
            lhs.cid == rhs.cid &&
            lhs.command == rhs.command &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.deletedForMe == rhs.deletedForMe &&
            lhs.deletedReplyCount == rhs.deletedReplyCount &&
            lhs.draft == rhs.draft &&
            lhs.html == rhs.html &&
            lhs.i18n == rhs.i18n &&
            lhs.id == rhs.id &&
            lhs.imageLabels == rhs.imageLabels &&
            lhs.latestReactions == rhs.latestReactions &&
            lhs.member == rhs.member &&
            lhs.mentionedChannel == rhs.mentionedChannel &&
            lhs.mentionedGroupIds == rhs.mentionedGroupIds &&
            lhs.mentionedHere == rhs.mentionedHere &&
            lhs.mentionedRoles == rhs.mentionedRoles &&
            lhs.mentionedUsers == rhs.mentionedUsers &&
            lhs.messageTextUpdatedAt == rhs.messageTextUpdatedAt &&
            lhs.mml == rhs.mml &&
            lhs.moderation == rhs.moderation &&
            lhs.ownReactions == rhs.ownReactions &&
            lhs.parentId == rhs.parentId &&
            lhs.pinExpires == rhs.pinExpires &&
            lhs.pinned == rhs.pinned &&
            lhs.pinnedAt == rhs.pinnedAt &&
            lhs.pinnedBy == rhs.pinnedBy &&
            lhs.poll == rhs.poll &&
            lhs.pollId == rhs.pollId &&
            lhs.quotedMessage == rhs.quotedMessage &&
            lhs.quotedMessageId == rhs.quotedMessageId &&
            lhs.reactionCounts == rhs.reactionCounts &&
            lhs.reactionGroups == rhs.reactionGroups &&
            lhs.reactionScores == rhs.reactionScores &&
            lhs.reminder == rhs.reminder &&
            lhs.replyCount == rhs.replyCount &&
            lhs.restrictedVisibility == rhs.restrictedVisibility &&
            lhs.shadowed == rhs.shadowed &&
            lhs.sharedLocation == rhs.sharedLocation &&
            lhs.showInChannel == rhs.showInChannel &&
            lhs.silent == rhs.silent &&
            lhs.text == rhs.text &&
            lhs.threadParticipants == rhs.threadParticipants &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(channel)
        hasher.combine(cid)
        hasher.combine(command)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(deletedForMe)
        hasher.combine(deletedReplyCount)
        hasher.combine(draft)
        hasher.combine(html)
        hasher.combine(i18n)
        hasher.combine(id)
        hasher.combine(imageLabels)
        hasher.combine(latestReactions)
        hasher.combine(member)
        hasher.combine(mentionedChannel)
        hasher.combine(mentionedGroupIds)
        hasher.combine(mentionedHere)
        hasher.combine(mentionedRoles)
        hasher.combine(mentionedUsers)
        hasher.combine(messageTextUpdatedAt)
        hasher.combine(mml)
        hasher.combine(moderation)
        hasher.combine(ownReactions)
        hasher.combine(parentId)
        hasher.combine(pinExpires)
        hasher.combine(pinned)
        hasher.combine(pinnedAt)
        hasher.combine(pinnedBy)
        hasher.combine(poll)
        hasher.combine(pollId)
        hasher.combine(quotedMessage)
        hasher.combine(quotedMessageId)
        hasher.combine(reactionCounts)
        hasher.combine(reactionGroups)
        hasher.combine(reactionScores)
        hasher.combine(reminder)
        hasher.combine(replyCount)
        hasher.combine(restrictedVisibility)
        hasher.combine(shadowed)
        hasher.combine(sharedLocation)
        hasher.combine(showInChannel)
        hasher.combine(silent)
        hasher.combine(text)
        hasher.combine(threadParticipants)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
