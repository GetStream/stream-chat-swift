//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchResultMessage: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]
    var channel: ChannelResponse?
    var cid: String
    var command: String?
    var createdAt: Date
    var custom: [String: RawJSON]
    var deletedAt: Date?
    var deletedForMe: Bool?
    var deletedReplyCount: Int
    var draft: DraftResponse?
    var html: String
    var i18n: [String: String]?
    var id: String
    var imageLabels: [String: [String]]?
    var latestReactions: [ReactionResponse]
    var member: ChannelMemberResponse?
    var mentionedChannel: Bool
    var mentionedGroupIds: [String]?
    var mentionedHere: Bool
    var mentionedRoles: [String]?
    var mentionedUsers: [UserResponse]
    var messageTextUpdatedAt: Date?
    var mml: String?
    var moderation: ModerationV2Response?
    var ownReactions: [ReactionResponse]
    var parentId: String?
    var pinExpires: Date?
    var pinned: Bool
    var pinnedAt: Date?
    var pinnedBy: UserResponse?
    var poll: PollResponseData?
    var pollId: String?
    var quotedMessage: MessageResponse?
    var quotedMessageId: String?
    var reactionCounts: [String: Int]
    var reactionGroups: [String: ReactionGroupResponse?]?
    var reactionScores: [String: Int]
    var reminder: ReminderResponseData?
    var replyCount: Int
    var restrictedVisibility: [String]
    var shadowed: Bool
    var sharedLocation: SharedLocationResponseData?
    var showInChannel: Bool?
    var silent: Bool
    var text: String
    var threadParticipants: [UserResponse]?
    var type: String
    var updatedAt: Date
    var user: UserResponse

    init(attachments: [Attachment], channel: ChannelResponse? = nil, cid: String, command: String? = nil, createdAt: Date, custom: [String: RawJSON], deletedAt: Date? = nil, deletedForMe: Bool? = nil, deletedReplyCount: Int, draft: DraftResponse? = nil, html: String, i18n: [String: String]? = nil, id: String, imageLabels: [String: [String]]? = nil, latestReactions: [ReactionResponse], member: ChannelMemberResponse? = nil, mentionedChannel: Bool, mentionedGroupIds: [String]? = nil, mentionedHere: Bool, mentionedRoles: [String]? = nil, mentionedUsers: [UserResponse], messageTextUpdatedAt: Date? = nil, mml: String? = nil, moderation: ModerationV2Response? = nil, ownReactions: [ReactionResponse], parentId: String? = nil, pinExpires: Date? = nil, pinned: Bool, pinnedAt: Date? = nil, pinnedBy: UserResponse? = nil, poll: PollResponseData? = nil, pollId: String? = nil, quotedMessage: MessageResponse? = nil, quotedMessageId: String? = nil, reactionCounts: [String: Int], reactionGroups: [String: ReactionGroupResponse?]? = nil, reactionScores: [String: Int], reminder: ReminderResponseData? = nil, replyCount: Int, restrictedVisibility: [String], shadowed: Bool, sharedLocation: SharedLocationResponseData? = nil, showInChannel: Bool? = nil, silent: Bool, text: String, threadParticipants: [UserResponse]? = nil, type: String, updatedAt: Date, user: UserResponse) {
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

    static func == (lhs: SearchResultMessage, rhs: SearchResultMessage) -> Bool {
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
