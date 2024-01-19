//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResultMessage: Codable, Hashable {
    public var pinExpires: Date?
    
    public var pinnedAt: Date?
    
    public var cid: String
    
    public var deletedReplyCount: Int
    
    public var ownReactions: [StreamChatReaction?]
    
    public var i18n: [String: RawJSON]?
    
    public var pinnedBy: StreamChatUserObject?
    
    public var updatedAt: Date
    
    public var silent: Bool
    
    public var channel: StreamChatChannelResponse?
    
    public var quotedMessageId: String?
    
    public var reactionCounts: [String: RawJSON]
    
    public var mml: String?
    
    public var beforeMessageSendFailed: Bool?
    
    public var createdAt: Date
    
    public var latestReactions: [StreamChatReaction?]
    
    public var pinned: Bool
    
    public var text: String
    
    public var user: StreamChatUserObject?
    
    public var imageLabels: [String: RawJSON]?
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var parentId: String?
    
    public var showInChannel: Bool?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var custom: [String: RawJSON]
    
    public var id: String
    
    public var reactionScores: [String: RawJSON]
    
    public var shadowed: Bool
    
    public var type: String
    
    public var attachments: [StreamChatAttachment?]
    
    public var html: String
    
    public var replyCount: Int
    
    public var command: String?
    
    public var deletedAt: Date?
    
    public var quotedMessage: StreamChatMessage?
    
    public init(pinExpires: Date?, pinnedAt: Date?, cid: String, deletedReplyCount: Int, ownReactions: [StreamChatReaction?], i18n: [String: RawJSON]?, pinnedBy: StreamChatUserObject?, updatedAt: Date, silent: Bool, channel: StreamChatChannelResponse?, quotedMessageId: String?, reactionCounts: [String: RawJSON], mml: String?, beforeMessageSendFailed: Bool?, createdAt: Date, latestReactions: [StreamChatReaction?], pinned: Bool, text: String, user: StreamChatUserObject?, imageLabels: [String: RawJSON]?, mentionedUsers: [StreamChatUserObject], parentId: String?, showInChannel: Bool?, threadParticipants: [StreamChatUserObject]?, custom: [String: RawJSON], id: String, reactionScores: [String: RawJSON], shadowed: Bool, type: String, attachments: [StreamChatAttachment?], html: String, replyCount: Int, command: String?, deletedAt: Date?, quotedMessage: StreamChatMessage?) {
        self.pinExpires = pinExpires
        
        self.pinnedAt = pinnedAt
        
        self.cid = cid
        
        self.deletedReplyCount = deletedReplyCount
        
        self.ownReactions = ownReactions
        
        self.i18n = i18n
        
        self.pinnedBy = pinnedBy
        
        self.updatedAt = updatedAt
        
        self.silent = silent
        
        self.channel = channel
        
        self.quotedMessageId = quotedMessageId
        
        self.reactionCounts = reactionCounts
        
        self.mml = mml
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.createdAt = createdAt
        
        self.latestReactions = latestReactions
        
        self.pinned = pinned
        
        self.text = text
        
        self.user = user
        
        self.imageLabels = imageLabels
        
        self.mentionedUsers = mentionedUsers
        
        self.parentId = parentId
        
        self.showInChannel = showInChannel
        
        self.threadParticipants = threadParticipants
        
        self.custom = custom
        
        self.id = id
        
        self.reactionScores = reactionScores
        
        self.shadowed = shadowed
        
        self.type = type
        
        self.attachments = attachments
        
        self.html = html
        
        self.replyCount = replyCount
        
        self.command = command
        
        self.deletedAt = deletedAt
        
        self.quotedMessage = quotedMessage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pinExpires = "pin_expires"
        
        case pinnedAt = "pinned_at"
        
        case cid
        
        case deletedReplyCount = "deleted_reply_count"
        
        case ownReactions = "own_reactions"
        
        case i18n
        
        case pinnedBy = "pinned_by"
        
        case updatedAt = "updated_at"
        
        case silent
        
        case channel
        
        case quotedMessageId = "quoted_message_id"
        
        case reactionCounts = "reaction_counts"
        
        case mml
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case createdAt = "created_at"
        
        case latestReactions = "latest_reactions"
        
        case pinned
        
        case text
        
        case user
        
        case imageLabels = "image_labels"
        
        case mentionedUsers = "mentioned_users"
        
        case parentId = "parent_id"
        
        case showInChannel = "show_in_channel"
        
        case threadParticipants = "thread_participants"
        
        case custom = "Custom"
        
        case id
        
        case reactionScores = "reaction_scores"
        
        case shadowed
        
        case type
        
        case attachments
        
        case html
        
        case replyCount = "reply_count"
        
        case command
        
        case deletedAt = "deleted_at"
        
        case quotedMessage = "quoted_message"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
    }
}
