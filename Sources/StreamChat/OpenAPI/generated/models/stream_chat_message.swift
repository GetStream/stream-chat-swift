//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class StreamChatMessage: Codable, Hashable {
    public var beforeMessageSendFailed: Bool?
    
    public var reactionCounts: [String: RawJSON]
    
    public var quotedMessage: StreamChatMessage?
    
    public var quotedMessageId: String?
    
    public var replyCount: Int
    
    public var showInChannel: Bool?
    
    public var html: String
    
    public var parentId: String?
    
    public var pinned: Bool
    
    public var deletedReplyCount: Int
    
    public var reactionScores: [String: RawJSON]
    
    public var user: StreamChatUserObject?
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var ownReactions: [StreamChatReaction?]
    
    public var pinnedBy: StreamChatUserObject?
    
    public var createdAt: String
    
    public var id: String
    
    public var latestReactions: [StreamChatReaction?]
    
    public var deletedAt: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var updatedAt: String
    
    public var mml: String?
    
    public var pinnedAt: String?
    
    public var type: String
    
    public var shadowed: Bool
    
    public var custom: [String: RawJSON]
    
    public var attachments: [StreamChatAttachment?]
    
    public var pinExpires: String?
    
    public var imageLabels: [String: RawJSON]?
    
    public var silent: Bool
    
    public var text: String
    
    public var cid: String
    
    public var command: String?
    
    public var i18n: [String: RawJSON]?
    
    public static func == (lhs: StreamChatMessage, rhs: StreamChatMessage) -> Bool {
        lhs.beforeMessageSendFailed == rhs.beforeMessageSendFailed
       
            && lhs.reactionCounts == rhs.reactionCounts
       
            && lhs.quotedMessage == rhs.quotedMessage
       
            && lhs.quotedMessageId == rhs.quotedMessageId
       
            && lhs.replyCount == rhs.replyCount
       
            && lhs.showInChannel == rhs.showInChannel
       
            && lhs.html == rhs.html
       
            && lhs.parentId == rhs.parentId
       
            && lhs.pinned == rhs.pinned
       
            && lhs.deletedReplyCount == rhs.deletedReplyCount
       
            && lhs.reactionScores == rhs.reactionScores
       
            && lhs.user == rhs.user
       
            && lhs.mentionedUsers == rhs.mentionedUsers
       
            && lhs.ownReactions == rhs.ownReactions
       
            && lhs.pinnedBy == rhs.pinnedBy
       
            && lhs.createdAt == rhs.createdAt
       
            && lhs.id == rhs.id
       
            && lhs.latestReactions == rhs.latestReactions
       
            && lhs.deletedAt == rhs.deletedAt
       
            && lhs.threadParticipants == rhs.threadParticipants
       
            && lhs.updatedAt == rhs.updatedAt
       
            && lhs.mml == rhs.mml
       
            && lhs.pinnedAt == rhs.pinnedAt
       
            && lhs.type == rhs.type
       
            && lhs.shadowed == rhs.shadowed
       
            && lhs.custom == rhs.custom
       
            && lhs.attachments == rhs.attachments
       
            && lhs.pinExpires == rhs.pinExpires
       
            && lhs.imageLabels == rhs.imageLabels
       
            && lhs.silent == rhs.silent
       
            && lhs.text == rhs.text
       
            && lhs.cid == rhs.cid
       
            && lhs.command == rhs.command
       
            && lhs.i18n == rhs.i18n
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(beforeMessageSendFailed)
        
        hasher.combine(reactionCounts)
        
        hasher.combine(quotedMessage)
        
        hasher.combine(quotedMessageId)
        
        hasher.combine(replyCount)
        
        hasher.combine(showInChannel)
        
        hasher.combine(html)
        
        hasher.combine(parentId)
        
        hasher.combine(pinned)
        
        hasher.combine(deletedReplyCount)
        
        hasher.combine(reactionScores)
        
        hasher.combine(user)
        
        hasher.combine(mentionedUsers)
        
        hasher.combine(ownReactions)
        
        hasher.combine(pinnedBy)
        
        hasher.combine(createdAt)
        
        hasher.combine(id)
        
        hasher.combine(latestReactions)
        
        hasher.combine(deletedAt)
        
        hasher.combine(threadParticipants)
        
        hasher.combine(updatedAt)
        
        hasher.combine(mml)
        
        hasher.combine(pinnedAt)
        
        hasher.combine(type)
        
        hasher.combine(shadowed)
        
        hasher.combine(custom)
        
        hasher.combine(attachments)
        
        hasher.combine(pinExpires)
        
        hasher.combine(imageLabels)
        
        hasher.combine(silent)
        
        hasher.combine(text)
        
        hasher.combine(cid)
        
        hasher.combine(command)
        
        hasher.combine(i18n)
    }

    public init(beforeMessageSendFailed: Bool?, reactionCounts: [String: RawJSON], quotedMessage: StreamChatMessage?, quotedMessageId: String?, replyCount: Int, showInChannel: Bool?, html: String, parentId: String?, pinned: Bool, deletedReplyCount: Int, reactionScores: [String: RawJSON], user: StreamChatUserObject?, mentionedUsers: [StreamChatUserObject], ownReactions: [StreamChatReaction?], pinnedBy: StreamChatUserObject?, createdAt: String, id: String, latestReactions: [StreamChatReaction?], deletedAt: String?, threadParticipants: [StreamChatUserObject]?, updatedAt: String, mml: String?, pinnedAt: String?, type: String, shadowed: Bool, custom: [String: RawJSON], attachments: [StreamChatAttachment?], pinExpires: String?, imageLabels: [String: RawJSON]?, silent: Bool, text: String, cid: String, command: String?, i18n: [String: RawJSON]?) {
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.reactionCounts = reactionCounts
        
        self.quotedMessage = quotedMessage
        
        self.quotedMessageId = quotedMessageId
        
        self.replyCount = replyCount
        
        self.showInChannel = showInChannel
        
        self.html = html
        
        self.parentId = parentId
        
        self.pinned = pinned
        
        self.deletedReplyCount = deletedReplyCount
        
        self.reactionScores = reactionScores
        
        self.user = user
        
        self.mentionedUsers = mentionedUsers
        
        self.ownReactions = ownReactions
        
        self.pinnedBy = pinnedBy
        
        self.createdAt = createdAt
        
        self.id = id
        
        self.latestReactions = latestReactions
        
        self.deletedAt = deletedAt
        
        self.threadParticipants = threadParticipants
        
        self.updatedAt = updatedAt
        
        self.mml = mml
        
        self.pinnedAt = pinnedAt
        
        self.type = type
        
        self.shadowed = shadowed
        
        self.custom = custom
        
        self.attachments = attachments
        
        self.pinExpires = pinExpires
        
        self.imageLabels = imageLabels
        
        self.silent = silent
        
        self.text = text
        
        self.cid = cid
        
        self.command = command
        
        self.i18n = i18n
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case reactionCounts = "reaction_counts"
        
        case quotedMessage = "quoted_message"
        
        case quotedMessageId = "quoted_message_id"
        
        case replyCount = "reply_count"
        
        case showInChannel = "show_in_channel"
        
        case html
        
        case parentId = "parent_id"
        
        case pinned
        
        case deletedReplyCount = "deleted_reply_count"
        
        case reactionScores = "reaction_scores"
        
        case user
        
        case mentionedUsers = "mentioned_users"
        
        case ownReactions = "own_reactions"
        
        case pinnedBy = "pinned_by"
        
        case createdAt = "created_at"
        
        case id
        
        case latestReactions = "latest_reactions"
        
        case deletedAt = "deleted_at"
        
        case threadParticipants = "thread_participants"
        
        case updatedAt = "updated_at"
        
        case mml
        
        case pinnedAt = "pinned_at"
        
        case type
        
        case shadowed
        
        case custom = "Custom"
        
        case attachments
        
        case pinExpires = "pin_expires"
        
        case imageLabels = "image_labels"
        
        case silent
        
        case text
        
        case cid
        
        case command
        
        case i18n
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(i18n, forKey: .i18n)
    }
}
