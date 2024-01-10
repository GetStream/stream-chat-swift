//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class StreamChatMessage: Codable, Hashable {
    public var updatedAt: String
    
    public var pinExpires: String?
    
    public var quotedMessageId: String?
    
    public var text: String
    
    public var imageLabels: [String: RawJSON]?
    
    public var silent: Bool
    
    public var ownReactions: [StreamChatReaction?]
    
    public var parentId: String?
    
    public var reactionCounts: [String: RawJSON]
    
    public var replyCount: Int
    
    public var showInChannel: Bool?
    
    public var attachments: [StreamChatAttachment?]
    
    public var deletedReplyCount: Int
    
    public var shadowed: Bool
    
    public var i18n: [String: RawJSON]?
    
    public var reactionScores: [String: RawJSON]
    
    public var latestReactions: [StreamChatReaction?]
    
    public var quotedMessage: StreamChatMessage?
    
    public var type: String
    
    public var createdAt: String
    
    public var deletedAt: String?
    
    public var command: String?
    
    public var html: String
    
    public var id: String
    
    public var mml: String?
    
    public var pinned: Bool
    
    public var pinnedBy: StreamChatUserObject?
    
    public var custom: [String: RawJSON]?
    
    public var cid: String
    
    public var user: StreamChatUserObject?
    
    public var pinnedAt: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var beforeMessageSendFailed: Bool?
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public static func == (lhs: StreamChatMessage, rhs: StreamChatMessage) -> Bool {
        lhs.updatedAt == rhs.updatedAt
       
            && lhs.pinExpires == rhs.pinExpires
       
            && lhs.quotedMessageId == rhs.quotedMessageId
       
            && lhs.text == rhs.text
       
            && lhs.imageLabels == rhs.imageLabels
       
            && lhs.silent == rhs.silent
       
            && lhs.ownReactions == rhs.ownReactions
       
            && lhs.parentId == rhs.parentId
       
            && lhs.reactionCounts == rhs.reactionCounts
       
            && lhs.replyCount == rhs.replyCount
       
            && lhs.showInChannel == rhs.showInChannel
       
            && lhs.attachments == rhs.attachments
       
            && lhs.deletedReplyCount == rhs.deletedReplyCount
       
            && lhs.shadowed == rhs.shadowed
       
            && lhs.i18n == rhs.i18n
       
            && lhs.reactionScores == rhs.reactionScores
       
            && lhs.latestReactions == rhs.latestReactions
       
            && lhs.quotedMessage == rhs.quotedMessage
       
            && lhs.type == rhs.type
       
            && lhs.createdAt == rhs.createdAt
       
            && lhs.deletedAt == rhs.deletedAt
       
            && lhs.command == rhs.command
       
            && lhs.html == rhs.html
       
            && lhs.id == rhs.id
       
            && lhs.mml == rhs.mml
       
            && lhs.pinned == rhs.pinned
       
            && lhs.pinnedBy == rhs.pinnedBy
       
            && lhs.custom == rhs.custom
       
            && lhs.cid == rhs.cid
       
            && lhs.user == rhs.user
       
            && lhs.pinnedAt == rhs.pinnedAt
       
            && lhs.threadParticipants == rhs.threadParticipants
       
            && lhs.beforeMessageSendFailed == rhs.beforeMessageSendFailed
       
            && lhs.mentionedUsers == rhs.mentionedUsers
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(updatedAt)
        
        hasher.combine(pinExpires)
        
        hasher.combine(quotedMessageId)
        
        hasher.combine(text)
        
        hasher.combine(imageLabels)
        
        hasher.combine(silent)
        
        hasher.combine(ownReactions)
        
        hasher.combine(parentId)
        
        hasher.combine(reactionCounts)
        
        hasher.combine(replyCount)
        
        hasher.combine(showInChannel)
        
        hasher.combine(attachments)
        
        hasher.combine(deletedReplyCount)
        
        hasher.combine(shadowed)
        
        hasher.combine(i18n)
        
        hasher.combine(reactionScores)
        
        hasher.combine(latestReactions)
        
        hasher.combine(quotedMessage)
        
        hasher.combine(type)
        
        hasher.combine(createdAt)
        
        hasher.combine(deletedAt)
        
        hasher.combine(command)
        
        hasher.combine(html)
        
        hasher.combine(id)
        
        hasher.combine(mml)
        
        hasher.combine(pinned)
        
        hasher.combine(pinnedBy)
        
        hasher.combine(custom)
        
        hasher.combine(cid)
        
        hasher.combine(user)
        
        hasher.combine(pinnedAt)
        
        hasher.combine(threadParticipants)
        
        hasher.combine(beforeMessageSendFailed)
        
        hasher.combine(mentionedUsers)
    }

    public init(updatedAt: String, pinExpires: String?, quotedMessageId: String?, text: String, imageLabels: [String: RawJSON]?, silent: Bool, ownReactions: [StreamChatReaction?], parentId: String?, reactionCounts: [String: RawJSON], replyCount: Int, showInChannel: Bool?, attachments: [StreamChatAttachment?], deletedReplyCount: Int, shadowed: Bool, i18n: [String: RawJSON]?, reactionScores: [String: RawJSON], latestReactions: [StreamChatReaction?], quotedMessage: StreamChatMessage?, type: String, createdAt: String, deletedAt: String?, command: String?, html: String, id: String, mml: String?, pinned: Bool, pinnedBy: StreamChatUserObject?, custom: [String: RawJSON], cid: String, user: StreamChatUserObject?, pinnedAt: String?, threadParticipants: [StreamChatUserObject]?, beforeMessageSendFailed: Bool?, mentionedUsers: [StreamChatUserObject]) {
        self.updatedAt = updatedAt
        
        self.pinExpires = pinExpires
        
        self.quotedMessageId = quotedMessageId
        
        self.text = text
        
        self.imageLabels = imageLabels
        
        self.silent = silent
        
        self.ownReactions = ownReactions
        
        self.parentId = parentId
        
        self.reactionCounts = reactionCounts
        
        self.replyCount = replyCount
        
        self.showInChannel = showInChannel
        
        self.attachments = attachments
        
        self.deletedReplyCount = deletedReplyCount
        
        self.shadowed = shadowed
        
        self.i18n = i18n
        
        self.reactionScores = reactionScores
        
        self.latestReactions = latestReactions
        
        self.quotedMessage = quotedMessage
        
        self.type = type
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.command = command
        
        self.html = html
        
        self.id = id
        
        self.mml = mml
        
        self.pinned = pinned
        
        self.pinnedBy = pinnedBy
        
        self.custom = custom
        
        self.cid = cid
        
        self.user = user
        
        self.pinnedAt = pinnedAt
        
        self.threadParticipants = threadParticipants
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.mentionedUsers = mentionedUsers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "updated_at"
        
        case pinExpires = "pin_expires"
        
        case quotedMessageId = "quoted_message_id"
        
        case text
        
        case imageLabels = "image_labels"
        
        case silent
        
        case ownReactions = "own_reactions"
        
        case parentId = "parent_id"
        
        case reactionCounts = "reaction_counts"
        
        case replyCount = "reply_count"
        
        case showInChannel = "show_in_channel"
        
        case attachments
        
        case deletedReplyCount = "deleted_reply_count"
        
        case shadowed
        
        case i18n
        
        case reactionScores = "reaction_scores"
        
        case latestReactions = "latest_reactions"
        
        case quotedMessage = "quoted_message"
        
        case type
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case command
        
        case html
        
        case id
        
        case mml
        
        case pinned
        
        case pinnedBy = "pinned_by"
        
        case custom = "Custom"
        
        case cid
        
        case user
        
        case pinnedAt = "pinned_at"
        
        case threadParticipants = "thread_participants"
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case mentionedUsers = "mentioned_users"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
    }
}
