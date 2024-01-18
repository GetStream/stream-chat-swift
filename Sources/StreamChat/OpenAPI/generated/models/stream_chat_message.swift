//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class StreamChatMessage: Codable, Hashable {
    public var id: String
    
    public var reactionScores: [String: RawJSON]
    
    public var type: String
    
    public var beforeMessageSendFailed: Bool?
    
    public var quotedMessage: StreamChatMessage?
    
    public var command: String?
    
    public var pinnedBy: StreamChatUserObject?
    
    public var reactionCounts: [String: RawJSON]
    
    public var silent: Bool
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var mml: String?
    
    public var quotedMessageId: String?
    
    public var showInChannel: Bool?
    
    public var text: String
    
    public var parentId: String?
    
    public var ownReactions: [StreamChatReaction?]
    
    public var pinned: Bool
    
    public var replyCount: Int
    
    public var html: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var deletedAt: Date?
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var pinnedAt: Date?
    
    public var shadowed: Bool
    
    public var updatedAt: Date
    
    public var attachments: [StreamChatAttachment?]
    
    public var user: StreamChatUserObject?
    
    public var i18n: [String: RawJSON]?
    
    public var latestReactions: [StreamChatReaction?]
    
    public var deletedReplyCount: Int
    
    public var imageLabels: [String: RawJSON]?
    
    public var pinExpires: Date?
    
    public var custom: [String: RawJSON]?
    
    public static func == (lhs: StreamChatMessage, rhs: StreamChatMessage) -> Bool {
        lhs.id == rhs.id
       
            && lhs.reactionScores == rhs.reactionScores
       
            && lhs.type == rhs.type
       
            && lhs.beforeMessageSendFailed == rhs.beforeMessageSendFailed
       
            && lhs.quotedMessage == rhs.quotedMessage
       
            && lhs.command == rhs.command
       
            && lhs.pinnedBy == rhs.pinnedBy
       
            && lhs.reactionCounts == rhs.reactionCounts
       
            && lhs.silent == rhs.silent
       
            && lhs.threadParticipants == rhs.threadParticipants
       
            && lhs.mml == rhs.mml
       
            && lhs.quotedMessageId == rhs.quotedMessageId
       
            && lhs.showInChannel == rhs.showInChannel
       
            && lhs.text == rhs.text
       
            && lhs.parentId == rhs.parentId
       
            && lhs.ownReactions == rhs.ownReactions
       
            && lhs.pinned == rhs.pinned
       
            && lhs.replyCount == rhs.replyCount
       
            && lhs.html == rhs.html
       
            && lhs.cid == rhs.cid
       
            && lhs.createdAt == rhs.createdAt
       
            && lhs.deletedAt == rhs.deletedAt
       
            && lhs.mentionedUsers == rhs.mentionedUsers
       
            && lhs.pinnedAt == rhs.pinnedAt
       
            && lhs.shadowed == rhs.shadowed
       
            && lhs.updatedAt == rhs.updatedAt
       
            && lhs.attachments == rhs.attachments
       
            && lhs.user == rhs.user
       
            && lhs.i18n == rhs.i18n
       
            && lhs.latestReactions == rhs.latestReactions
       
            && lhs.deletedReplyCount == rhs.deletedReplyCount
       
            && lhs.imageLabels == rhs.imageLabels
       
            && lhs.pinExpires == rhs.pinExpires
       
            && lhs.custom == rhs.custom
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        
        hasher.combine(reactionScores)
        
        hasher.combine(type)
        
        hasher.combine(beforeMessageSendFailed)
        
        hasher.combine(quotedMessage)
        
        hasher.combine(command)
        
        hasher.combine(pinnedBy)
        
        hasher.combine(reactionCounts)
        
        hasher.combine(silent)
        
        hasher.combine(threadParticipants)
        
        hasher.combine(mml)
        
        hasher.combine(quotedMessageId)
        
        hasher.combine(showInChannel)
        
        hasher.combine(text)
        
        hasher.combine(parentId)
        
        hasher.combine(ownReactions)
        
        hasher.combine(pinned)
        
        hasher.combine(replyCount)
        
        hasher.combine(html)
        
        hasher.combine(cid)
        
        hasher.combine(createdAt)
        
        hasher.combine(deletedAt)
        
        hasher.combine(mentionedUsers)
        
        hasher.combine(pinnedAt)
        
        hasher.combine(shadowed)
        
        hasher.combine(updatedAt)
        
        hasher.combine(attachments)
        
        hasher.combine(user)
        
        hasher.combine(i18n)
        
        hasher.combine(latestReactions)
        
        hasher.combine(deletedReplyCount)
        
        hasher.combine(imageLabels)
        
        hasher.combine(pinExpires)
        
        hasher.combine(custom)
    }

    public init(id: String, reactionScores: [String: RawJSON], type: String, beforeMessageSendFailed: Bool?, quotedMessage: StreamChatMessage?, command: String?, pinnedBy: StreamChatUserObject?, reactionCounts: [String: RawJSON], silent: Bool, threadParticipants: [StreamChatUserObject]?, mml: String?, quotedMessageId: String?, showInChannel: Bool?, text: String, parentId: String?, ownReactions: [StreamChatReaction?], pinned: Bool, replyCount: Int, html: String, cid: String, createdAt: Date, deletedAt: Date?, mentionedUsers: [StreamChatUserObject], pinnedAt: Date?, shadowed: Bool, updatedAt: Date, attachments: [StreamChatAttachment?], user: StreamChatUserObject?, i18n: [String: RawJSON]?, latestReactions: [StreamChatReaction?], deletedReplyCount: Int, imageLabels: [String: RawJSON]?, pinExpires: Date?, custom: [String: RawJSON]) {
        self.id = id
        
        self.reactionScores = reactionScores
        
        self.type = type
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.quotedMessage = quotedMessage
        
        self.command = command
        
        self.pinnedBy = pinnedBy
        
        self.reactionCounts = reactionCounts
        
        self.silent = silent
        
        self.threadParticipants = threadParticipants
        
        self.mml = mml
        
        self.quotedMessageId = quotedMessageId
        
        self.showInChannel = showInChannel
        
        self.text = text
        
        self.parentId = parentId
        
        self.ownReactions = ownReactions
        
        self.pinned = pinned
        
        self.replyCount = replyCount
        
        self.html = html
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.mentionedUsers = mentionedUsers
        
        self.pinnedAt = pinnedAt
        
        self.shadowed = shadowed
        
        self.updatedAt = updatedAt
        
        self.attachments = attachments
        
        self.user = user
        
        self.i18n = i18n
        
        self.latestReactions = latestReactions
        
        self.deletedReplyCount = deletedReplyCount
        
        self.imageLabels = imageLabels
        
        self.pinExpires = pinExpires
        
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case reactionScores = "reaction_scores"
        
        case type
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case quotedMessage = "quoted_message"
        
        case command
        
        case pinnedBy = "pinned_by"
        
        case reactionCounts = "reaction_counts"
        
        case silent
        
        case threadParticipants = "thread_participants"
        
        case mml
        
        case quotedMessageId = "quoted_message_id"
        
        case showInChannel = "show_in_channel"
        
        case text
        
        case parentId = "parent_id"
        
        case ownReactions = "own_reactions"
        
        case pinned
        
        case replyCount = "reply_count"
        
        case html
        
        case cid
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case mentionedUsers = "mentioned_users"
        
        case pinnedAt = "pinned_at"
        
        case shadowed
        
        case updatedAt = "updated_at"
        
        case attachments
        
        case user
        
        case i18n
        
        case latestReactions = "latest_reactions"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case imageLabels = "image_labels"
        
        case pinExpires = "pin_expires"
        
        case custom = "Custom"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(custom, forKey: .custom)
    }
}
