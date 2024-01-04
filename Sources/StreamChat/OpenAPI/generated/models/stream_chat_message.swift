//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class StreamChatMessage: Codable, Hashable {
    public static func == (lhs: StreamChatMessage, rhs: StreamChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var latestReactions: [StreamChatReaction?]
    
    public var pinned: Bool
    
    public var showInChannel: Bool?
    
    public var silent: Bool
    
    public var cid: String
    
    public var parentId: String?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var command: String?
    
    public var i18n: [String: RawJSON]?
    
    public var custom: [String: RawJSON]
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var mml: String?
    
    public var quotedMessage: StreamChatMessage?
    
    public var reactionScores: [String: RawJSON]
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var beforeMessageSendFailed: Bool?
    
    public var pinnedAt: String?
    
    public var pinnedBy: StreamChatUserObject?
    
    public var html: String
    
    public var deletedAt: String?
    
    public var deletedReplyCount: Int
    
    public var imageLabels: [String: RawJSON]?
    
    public var ownReactions: [StreamChatReaction?]
    
    public var quotedMessageId: String?
    
    public var replyCount: Int
    
    public var text: String
    
    public var attachments: [StreamChatAttachment?]
    
    public var reactionCounts: [String: RawJSON]
    
    public var shadowed: Bool
    
    public var createdAt: String
    
    public var pinExpires: String?
    
    public var updatedAt: String
    
    public var id: String
    
    public init(latestReactions: [StreamChatReaction?], pinned: Bool, showInChannel: Bool?, silent: Bool, cid: String, parentId: String?, threadParticipants: [StreamChatUserObject]?, command: String?, i18n: [String: RawJSON]?, custom: [String: RawJSON], mentionedUsers: [StreamChatUserObject], mml: String?, quotedMessage: StreamChatMessage?, reactionScores: [String: RawJSON], type: String, user: StreamChatUserObject?, beforeMessageSendFailed: Bool?, pinnedAt: String?, pinnedBy: StreamChatUserObject?, html: String, deletedAt: String?, deletedReplyCount: Int, imageLabels: [String: RawJSON]?, ownReactions: [StreamChatReaction?], quotedMessageId: String?, replyCount: Int, text: String, attachments: [StreamChatAttachment?], reactionCounts: [String: RawJSON], shadowed: Bool, createdAt: String, pinExpires: String?, updatedAt: String, id: String) {
        self.latestReactions = latestReactions
        
        self.pinned = pinned
        
        self.showInChannel = showInChannel
        
        self.silent = silent
        
        self.cid = cid
        
        self.parentId = parentId
        
        self.threadParticipants = threadParticipants
        
        self.command = command
        
        self.i18n = i18n
        
        self.custom = custom
        
        self.mentionedUsers = mentionedUsers
        
        self.mml = mml
        
        self.quotedMessage = quotedMessage
        
        self.reactionScores = reactionScores
        
        self.type = type
        
        self.user = user
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.pinnedAt = pinnedAt
        
        self.pinnedBy = pinnedBy
        
        self.html = html
        
        self.deletedAt = deletedAt
        
        self.deletedReplyCount = deletedReplyCount
        
        self.imageLabels = imageLabels
        
        self.ownReactions = ownReactions
        
        self.quotedMessageId = quotedMessageId
        
        self.replyCount = replyCount
        
        self.text = text
        
        self.attachments = attachments
        
        self.reactionCounts = reactionCounts
        
        self.shadowed = shadowed
        
        self.createdAt = createdAt
        
        self.pinExpires = pinExpires
        
        self.updatedAt = updatedAt
        
        self.id = id
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case latestReactions = "latest_reactions"
        
        case pinned
        
        case showInChannel = "show_in_channel"
        
        case silent
        
        case cid
        
        case parentId = "parent_id"
        
        case threadParticipants = "thread_participants"
        
        case command
        
        case i18n
        
        case custom = "Custom"
        
        case mentionedUsers = "mentioned_users"
        
        case mml
        
        case quotedMessage = "quoted_message"
        
        case reactionScores = "reaction_scores"
        
        case type
        
        case user
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case pinnedAt = "pinned_at"
        
        case pinnedBy = "pinned_by"
        
        case html
        
        case deletedAt = "deleted_at"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case imageLabels = "image_labels"
        
        case ownReactions = "own_reactions"
        
        case quotedMessageId = "quoted_message_id"
        
        case replyCount = "reply_count"
        
        case text
        
        case attachments
        
        case reactionCounts = "reaction_counts"
        
        case shadowed
        
        case createdAt = "created_at"
        
        case pinExpires = "pin_expires"
        
        case updatedAt = "updated_at"
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(id, forKey: .id)
    }
}
