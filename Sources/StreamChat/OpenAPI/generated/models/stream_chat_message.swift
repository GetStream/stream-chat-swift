//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class StreamChatMessage: Codable, Hashable {
    public var pinned: Bool
    
    public var showInChannel: Bool?
    
    public var createdAt: Date
    
    public var mml: String?
    
    public var pinnedBy: StreamChatUserObject?
    
    public var updatedAt: Date
    
    public var deletedReplyCount: Int
    
    public var imageLabels: [String: RawJSON]?
    
    public var latestReactions: [StreamChatReaction?]
    
    public var quotedMessage: StreamChatMessage?
    
    public var reactionCounts: [String: RawJSON]
    
    public var reactionScores: [String: RawJSON]
    
    public var i18n: [String: RawJSON]?
    
    public var ownReactions: [StreamChatReaction?]
    
    public var type: String
    
    public var beforeMessageSendFailed: Bool?
    
    public var deletedAt: Date?
    
    public var parentId: String?
    
    public var shadowed: Bool
    
    public var silent: Bool
    
    public var cid: String
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var text: String
    
    public var html: String
    
    public var pinnedAt: Date?
    
    public var quotedMessageId: String?
    
    public var replyCount: Int
    
    public var custom: [String: RawJSON]?
    
    public var command: String?
    
    public var id: String
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var pinExpires: Date?
    
    public var user: StreamChatUserObject?
    
    public var attachments: [StreamChatAttachment?]
    
    public static func == (lhs: StreamChatMessage, rhs: StreamChatMessage) -> Bool {
        lhs.pinned == rhs.pinned
       
            && lhs.showInChannel == rhs.showInChannel
       
            && lhs.createdAt == rhs.createdAt
       
            && lhs.mml == rhs.mml
       
            && lhs.pinnedBy == rhs.pinnedBy
       
            && lhs.updatedAt == rhs.updatedAt
       
            && lhs.deletedReplyCount == rhs.deletedReplyCount
       
            && lhs.imageLabels == rhs.imageLabels
       
            && lhs.latestReactions == rhs.latestReactions
       
            && lhs.quotedMessage == rhs.quotedMessage
       
            && lhs.reactionCounts == rhs.reactionCounts
       
            && lhs.reactionScores == rhs.reactionScores
       
            && lhs.i18n == rhs.i18n
       
            && lhs.ownReactions == rhs.ownReactions
       
            && lhs.type == rhs.type
       
            && lhs.beforeMessageSendFailed == rhs.beforeMessageSendFailed
       
            && lhs.deletedAt == rhs.deletedAt
       
            && lhs.parentId == rhs.parentId
       
            && lhs.shadowed == rhs.shadowed
       
            && lhs.silent == rhs.silent
       
            && lhs.cid == rhs.cid
       
            && lhs.threadParticipants == rhs.threadParticipants
       
            && lhs.text == rhs.text
       
            && lhs.html == rhs.html
       
            && lhs.pinnedAt == rhs.pinnedAt
       
            && lhs.quotedMessageId == rhs.quotedMessageId
       
            && lhs.replyCount == rhs.replyCount
       
            && lhs.custom == rhs.custom
       
            && lhs.command == rhs.command
       
            && lhs.id == rhs.id
       
            && lhs.mentionedUsers == rhs.mentionedUsers
       
            && lhs.pinExpires == rhs.pinExpires
       
            && lhs.user == rhs.user
       
            && lhs.attachments == rhs.attachments
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(pinned)
        
        hasher.combine(showInChannel)
        
        hasher.combine(createdAt)
        
        hasher.combine(mml)
        
        hasher.combine(pinnedBy)
        
        hasher.combine(updatedAt)
        
        hasher.combine(deletedReplyCount)
        
        hasher.combine(imageLabels)
        
        hasher.combine(latestReactions)
        
        hasher.combine(quotedMessage)
        
        hasher.combine(reactionCounts)
        
        hasher.combine(reactionScores)
        
        hasher.combine(i18n)
        
        hasher.combine(ownReactions)
        
        hasher.combine(type)
        
        hasher.combine(beforeMessageSendFailed)
        
        hasher.combine(deletedAt)
        
        hasher.combine(parentId)
        
        hasher.combine(shadowed)
        
        hasher.combine(silent)
        
        hasher.combine(cid)
        
        hasher.combine(threadParticipants)
        
        hasher.combine(text)
        
        hasher.combine(html)
        
        hasher.combine(pinnedAt)
        
        hasher.combine(quotedMessageId)
        
        hasher.combine(replyCount)
        
        hasher.combine(custom)
        
        hasher.combine(command)
        
        hasher.combine(id)
        
        hasher.combine(mentionedUsers)
        
        hasher.combine(pinExpires)
        
        hasher.combine(user)
        
        hasher.combine(attachments)
    }

    public init(pinned: Bool, showInChannel: Bool?, createdAt: Date, mml: String?, pinnedBy: StreamChatUserObject?, updatedAt: Date, deletedReplyCount: Int, imageLabels: [String: RawJSON]?, latestReactions: [StreamChatReaction?], quotedMessage: StreamChatMessage?, reactionCounts: [String: RawJSON], reactionScores: [String: RawJSON], i18n: [String: RawJSON]?, ownReactions: [StreamChatReaction?], type: String, beforeMessageSendFailed: Bool?, deletedAt: Date?, parentId: String?, shadowed: Bool, silent: Bool, cid: String, threadParticipants: [StreamChatUserObject]?, text: String, html: String, pinnedAt: Date?, quotedMessageId: String?, replyCount: Int, custom: [String: RawJSON], command: String?, id: String, mentionedUsers: [StreamChatUserObject], pinExpires: Date?, user: StreamChatUserObject?, attachments: [StreamChatAttachment?]) {
        self.pinned = pinned
        
        self.showInChannel = showInChannel
        
        self.createdAt = createdAt
        
        self.mml = mml
        
        self.pinnedBy = pinnedBy
        
        self.updatedAt = updatedAt
        
        self.deletedReplyCount = deletedReplyCount
        
        self.imageLabels = imageLabels
        
        self.latestReactions = latestReactions
        
        self.quotedMessage = quotedMessage
        
        self.reactionCounts = reactionCounts
        
        self.reactionScores = reactionScores
        
        self.i18n = i18n
        
        self.ownReactions = ownReactions
        
        self.type = type
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.deletedAt = deletedAt
        
        self.parentId = parentId
        
        self.shadowed = shadowed
        
        self.silent = silent
        
        self.cid = cid
        
        self.threadParticipants = threadParticipants
        
        self.text = text
        
        self.html = html
        
        self.pinnedAt = pinnedAt
        
        self.quotedMessageId = quotedMessageId
        
        self.replyCount = replyCount
        
        self.custom = custom
        
        self.command = command
        
        self.id = id
        
        self.mentionedUsers = mentionedUsers
        
        self.pinExpires = pinExpires
        
        self.user = user
        
        self.attachments = attachments
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pinned
        
        case showInChannel = "show_in_channel"
        
        case createdAt = "created_at"
        
        case mml
        
        case pinnedBy = "pinned_by"
        
        case updatedAt = "updated_at"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case imageLabels = "image_labels"
        
        case latestReactions = "latest_reactions"
        
        case quotedMessage = "quoted_message"
        
        case reactionCounts = "reaction_counts"
        
        case reactionScores = "reaction_scores"
        
        case i18n
        
        case ownReactions = "own_reactions"
        
        case type
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case deletedAt = "deleted_at"
        
        case parentId = "parent_id"
        
        case shadowed
        
        case silent
        
        case cid
        
        case threadParticipants = "thread_participants"
        
        case text
        
        case html
        
        case pinnedAt = "pinned_at"
        
        case quotedMessageId = "quoted_message_id"
        
        case replyCount = "reply_count"
        
        case custom = "Custom"
        
        case command
        
        case id
        
        case mentionedUsers = "mentioned_users"
        
        case pinExpires = "pin_expires"
        
        case user
        
        case attachments
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(attachments, forKey: .attachments)
    }
}
