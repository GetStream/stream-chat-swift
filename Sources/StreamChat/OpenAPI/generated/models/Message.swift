//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class Message: Codable, Hashable {
    public var cid: String
    public var createdAt: Date
    public var deletedReplyCount: Int
    public var html: String
    public var id: String
    public var pinned: Bool
    public var replyCount: Int
    public var shadowed: Bool
    public var silent: Bool
    public var text: String
    public var type: String
    public var updatedAt: Date
    public var attachments: [Attachment?]
    public var latestReactions: [Reaction?]
    public var mentionedUsers: [UserObject]
    public var ownReactions: [Reaction?]
    public var custom: [String: RawJSON]?
    public var reactionCounts: [String: Int]
    public var reactionScores: [String: Int]
    public var beforeMessageSendFailed: Bool? = nil
    public var command: String? = nil
    public var deletedAt: Date? = nil
    public var mml: String? = nil
    public var parentId: String? = nil
    public var pinExpires: Date? = nil
    public var pinnedAt: Date? = nil
    public var quotedMessageId: String? = nil
    public var showInChannel: Bool? = nil
    public var threadParticipants: [UserObject]? = nil
    public var i18n: [String: String]? = nil
    public var imageLabels: [String: [String]]? = nil
    public var pinnedBy: UserObject? = nil
    public var quotedMessage: Message? = nil
    public var user: UserObject? = nil

    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.cid == rhs.cid
            && lhs.createdAt == rhs.createdAt
            && lhs.deletedReplyCount == rhs.deletedReplyCount
            && lhs.html == rhs.html
            && lhs.id == rhs.id
            && lhs.pinned == rhs.pinned
            && lhs.replyCount == rhs.replyCount
            && lhs.shadowed == rhs.shadowed
            && lhs.silent == rhs.silent
            && lhs.text == rhs.text
            && lhs.type == rhs.type
            && lhs.updatedAt == rhs.updatedAt
            && lhs.attachments == rhs.attachments
            && lhs.latestReactions == rhs.latestReactions
            && lhs.mentionedUsers == rhs.mentionedUsers
            && lhs.ownReactions == rhs.ownReactions
            && lhs.custom == rhs.custom
            && lhs.reactionCounts == rhs.reactionCounts
            && lhs.reactionScores == rhs.reactionScores
            && lhs.beforeMessageSendFailed == rhs.beforeMessageSendFailed
            && lhs.command == rhs.command
            && lhs.deletedAt == rhs.deletedAt
            && lhs.mml == rhs.mml
            && lhs.parentId == rhs.parentId
            && lhs.pinExpires == rhs.pinExpires
            && lhs.pinnedAt == rhs.pinnedAt
            && lhs.quotedMessageId == rhs.quotedMessageId
            && lhs.showInChannel == rhs.showInChannel
            && lhs.threadParticipants == rhs.threadParticipants
            && lhs.i18n == rhs.i18n
            && lhs.imageLabels == rhs.imageLabels
            && lhs.pinnedBy == rhs.pinnedBy
            && lhs.quotedMessage == rhs.quotedMessage
            && lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(deletedReplyCount)
        hasher.combine(html)
        hasher.combine(id)
        hasher.combine(pinned)
        hasher.combine(replyCount)
        hasher.combine(shadowed)
        hasher.combine(silent)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(attachments)
        hasher.combine(latestReactions)
        hasher.combine(mentionedUsers)
        hasher.combine(ownReactions)
        hasher.combine(custom)
        hasher.combine(reactionCounts)
        hasher.combine(reactionScores)
        hasher.combine(beforeMessageSendFailed)
        hasher.combine(command)
        hasher.combine(deletedAt)
        hasher.combine(mml)
        hasher.combine(parentId)
        hasher.combine(pinExpires)
        hasher.combine(pinnedAt)
        hasher.combine(quotedMessageId)
        hasher.combine(showInChannel)
        hasher.combine(threadParticipants)
        hasher.combine(i18n)
        hasher.combine(imageLabels)
        hasher.combine(pinnedBy)
        hasher.combine(quotedMessage)
        hasher.combine(user)
    }

    public init(cid: String, createdAt: Date, deletedReplyCount: Int, html: String, id: String, pinned: Bool, replyCount: Int, shadowed: Bool, silent: Bool, text: String, type: String, updatedAt: Date, attachments: [Attachment?], latestReactions: [Reaction?], mentionedUsers: [UserObject], ownReactions: [Reaction?], custom: [String: RawJSON], reactionCounts: [String: Int], reactionScores: [String: Int], beforeMessageSendFailed: Bool? = nil, command: String? = nil, deletedAt: Date? = nil, mml: String? = nil, parentId: String? = nil, pinExpires: Date? = nil, pinnedAt: Date? = nil, quotedMessageId: String? = nil, showInChannel: Bool? = nil, threadParticipants: [UserObject]? = nil, i18n: [String: String]? = nil, imageLabels: [String: [String]]? = nil, pinnedBy: UserObject? = nil, quotedMessage: Message? = nil, user: UserObject? = nil) {
        self.cid = cid
        self.createdAt = createdAt
        self.deletedReplyCount = deletedReplyCount
        self.html = html
        self.id = id
        self.pinned = pinned
        self.replyCount = replyCount
        self.shadowed = shadowed
        self.silent = silent
        self.text = text
        self.type = type
        self.updatedAt = updatedAt
        self.attachments = attachments
        self.latestReactions = latestReactions
        self.mentionedUsers = mentionedUsers
        self.ownReactions = ownReactions
        self.custom = custom
        self.reactionCounts = reactionCounts
        self.reactionScores = reactionScores
        self.beforeMessageSendFailed = beforeMessageSendFailed
        self.command = command
        self.deletedAt = deletedAt
        self.mml = mml
        self.parentId = parentId
        self.pinExpires = pinExpires
        self.pinnedAt = pinnedAt
        self.quotedMessageId = quotedMessageId
        self.showInChannel = showInChannel
        self.threadParticipants = threadParticipants
        self.i18n = i18n
        self.imageLabels = imageLabels
        self.pinnedBy = pinnedBy
        self.quotedMessage = quotedMessage
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case deletedReplyCount = "deleted_reply_count"
        case html
        case id
        case pinned
        case replyCount = "reply_count"
        case shadowed
        case silent
        case text
        case type
        case updatedAt = "updated_at"
        case attachments
        case latestReactions = "latest_reactions"
        case mentionedUsers = "mentioned_users"
        case ownReactions = "own_reactions"
        case custom
        case reactionCounts = "reaction_counts"
        case reactionScores = "reaction_scores"
        case beforeMessageSendFailed = "before_message_send_failed"
        case command
        case deletedAt = "deleted_at"
        case mml
        case parentId = "parent_id"
        case pinExpires = "pin_expires"
        case pinnedAt = "pinned_at"
        case quotedMessageId = "quoted_message_id"
        case showInChannel = "show_in_channel"
        case threadParticipants = "thread_participants"
        case i18n
        case imageLabels = "image_labels"
        case pinnedBy = "pinned_by"
        case quotedMessage = "quoted_message"
        case user
    }
}
