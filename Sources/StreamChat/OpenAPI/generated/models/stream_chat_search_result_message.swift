//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResultMessage: Codable, Hashable {
    public var pinnedBy: StreamChatUserObject?
    
    public var reactionScores: [String: RawJSON]
    
    public var type: String
    
    public var cid: String
    
    public var command: String?
    
    public var createdAt: String
    
    public var mml: String?
    
    public var pinnedAt: String?
    
    public var user: StreamChatUserObject?
    
    public var showInChannel: Bool?
    
    public var deletedReplyCount: Int
    
    public var id: String
    
    public var latestReactions: [StreamChatReaction?]
    
    public var quotedMessage: StreamChatMessage?
    
    public var replyCount: Int
    
    public var beforeMessageSendFailed: Bool?
    
    public var html: String
    
    public var imageLabels: [String: RawJSON]?
    
    public var parentId: String?
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var updatedAt: String
    
    public var i18n: [String: RawJSON]?
    
    public var quotedMessageId: String?
    
    public var silent: Bool
    
    public var text: String
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var custom: [String: RawJSON]
    
    public var channel: StreamChatChannelResponse?
    
    public var pinExpires: String?
    
    public var shadowed: Bool
    
    public var attachments: [StreamChatAttachment?]
    
    public var deletedAt: String?
    
    public var ownReactions: [StreamChatReaction?]
    
    public var pinned: Bool
    
    public var reactionCounts: [String: RawJSON]
    
    public init(pinnedBy: StreamChatUserObject?, reactionScores: [String: RawJSON], type: String, cid: String, command: String?, createdAt: String, mml: String?, pinnedAt: String?, user: StreamChatUserObject?, showInChannel: Bool?, deletedReplyCount: Int, id: String, latestReactions: [StreamChatReaction?], quotedMessage: StreamChatMessage?, replyCount: Int, beforeMessageSendFailed: Bool?, html: String, imageLabels: [String: RawJSON]?, parentId: String?, mentionedUsers: [StreamChatUserObject], updatedAt: String, i18n: [String: RawJSON]?, quotedMessageId: String?, silent: Bool, text: String, threadParticipants: [StreamChatUserObject]?, custom: [String: RawJSON], channel: StreamChatChannelResponse?, pinExpires: String?, shadowed: Bool, attachments: [StreamChatAttachment?], deletedAt: String?, ownReactions: [StreamChatReaction?], pinned: Bool, reactionCounts: [String: RawJSON]) {
        self.pinnedBy = pinnedBy
        
        self.reactionScores = reactionScores
        
        self.type = type
        
        self.cid = cid
        
        self.command = command
        
        self.createdAt = createdAt
        
        self.mml = mml
        
        self.pinnedAt = pinnedAt
        
        self.user = user
        
        self.showInChannel = showInChannel
        
        self.deletedReplyCount = deletedReplyCount
        
        self.id = id
        
        self.latestReactions = latestReactions
        
        self.quotedMessage = quotedMessage
        
        self.replyCount = replyCount
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.html = html
        
        self.imageLabels = imageLabels
        
        self.parentId = parentId
        
        self.mentionedUsers = mentionedUsers
        
        self.updatedAt = updatedAt
        
        self.i18n = i18n
        
        self.quotedMessageId = quotedMessageId
        
        self.silent = silent
        
        self.text = text
        
        self.threadParticipants = threadParticipants
        
        self.custom = custom
        
        self.channel = channel
        
        self.pinExpires = pinExpires
        
        self.shadowed = shadowed
        
        self.attachments = attachments
        
        self.deletedAt = deletedAt
        
        self.ownReactions = ownReactions
        
        self.pinned = pinned
        
        self.reactionCounts = reactionCounts
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pinnedBy = "pinned_by"
        
        case reactionScores = "reaction_scores"
        
        case type
        
        case cid
        
        case command
        
        case createdAt = "created_at"
        
        case mml
        
        case pinnedAt = "pinned_at"
        
        case user
        
        case showInChannel = "show_in_channel"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case id
        
        case latestReactions = "latest_reactions"
        
        case quotedMessage = "quoted_message"
        
        case replyCount = "reply_count"
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case html
        
        case imageLabels = "image_labels"
        
        case parentId = "parent_id"
        
        case mentionedUsers = "mentioned_users"
        
        case updatedAt = "updated_at"
        
        case i18n
        
        case quotedMessageId = "quoted_message_id"
        
        case silent
        
        case text
        
        case threadParticipants = "thread_participants"
        
        case custom = "Custom"
        
        case channel
        
        case pinExpires = "pin_expires"
        
        case shadowed
        
        case attachments
        
        case deletedAt = "deleted_at"
        
        case ownReactions = "own_reactions"
        
        case pinned
        
        case reactionCounts = "reaction_counts"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
    }
}
