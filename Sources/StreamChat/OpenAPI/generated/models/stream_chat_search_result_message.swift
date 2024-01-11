//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResultMessage: Codable, Hashable {
    public var updatedAt: String
    
    public var channel: StreamChatChannelResponse?
    
    public var createdAt: String
    
    public var deletedReplyCount: Int
    
    public var imageLabels: [String: RawJSON]?
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var text: String
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var user: StreamChatUserObject?
    
    public var html: String
    
    public var mml: String?
    
    public var shadowed: Bool
    
    public var cid: String
    
    public var pinnedBy: StreamChatUserObject?
    
    public var replyCount: Int
    
    public var beforeMessageSendFailed: Bool?
    
    public var latestReactions: [StreamChatReaction?]
    
    public var pinExpires: String?
    
    public var pinned: Bool
    
    public var pinnedAt: String?
    
    public var quotedMessageId: String?
    
    public var deletedAt: String?
    
    public var parentId: String?
    
    public var silent: Bool
    
    public var command: String?
    
    public var quotedMessage: StreamChatMessage?
    
    public var reactionCounts: [String: RawJSON]
    
    public var showInChannel: Bool?
    
    public var custom: [String: RawJSON]
    
    public var i18n: [String: RawJSON]?
    
    public var ownReactions: [StreamChatReaction?]
    
    public var attachments: [StreamChatAttachment?]
    
    public var id: String
    
    public var reactionScores: [String: RawJSON]
    
    public var type: String
    
    public init(updatedAt: String, channel: StreamChatChannelResponse?, createdAt: String, deletedReplyCount: Int, imageLabels: [String: RawJSON]?, mentionedUsers: [StreamChatUserObject], text: String, threadParticipants: [StreamChatUserObject]?, user: StreamChatUserObject?, html: String, mml: String?, shadowed: Bool, cid: String, pinnedBy: StreamChatUserObject?, replyCount: Int, beforeMessageSendFailed: Bool?, latestReactions: [StreamChatReaction?], pinExpires: String?, pinned: Bool, pinnedAt: String?, quotedMessageId: String?, deletedAt: String?, parentId: String?, silent: Bool, command: String?, quotedMessage: StreamChatMessage?, reactionCounts: [String: RawJSON], showInChannel: Bool?, custom: [String: RawJSON], i18n: [String: RawJSON]?, ownReactions: [StreamChatReaction?], attachments: [StreamChatAttachment?], id: String, reactionScores: [String: RawJSON], type: String) {
        self.updatedAt = updatedAt
        
        self.channel = channel
        
        self.createdAt = createdAt
        
        self.deletedReplyCount = deletedReplyCount
        
        self.imageLabels = imageLabels
        
        self.mentionedUsers = mentionedUsers
        
        self.text = text
        
        self.threadParticipants = threadParticipants
        
        self.user = user
        
        self.html = html
        
        self.mml = mml
        
        self.shadowed = shadowed
        
        self.cid = cid
        
        self.pinnedBy = pinnedBy
        
        self.replyCount = replyCount
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.latestReactions = latestReactions
        
        self.pinExpires = pinExpires
        
        self.pinned = pinned
        
        self.pinnedAt = pinnedAt
        
        self.quotedMessageId = quotedMessageId
        
        self.deletedAt = deletedAt
        
        self.parentId = parentId
        
        self.silent = silent
        
        self.command = command
        
        self.quotedMessage = quotedMessage
        
        self.reactionCounts = reactionCounts
        
        self.showInChannel = showInChannel
        
        self.custom = custom
        
        self.i18n = i18n
        
        self.ownReactions = ownReactions
        
        self.attachments = attachments
        
        self.id = id
        
        self.reactionScores = reactionScores
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "updated_at"
        
        case channel
        
        case createdAt = "created_at"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case imageLabels = "image_labels"
        
        case mentionedUsers = "mentioned_users"
        
        case text
        
        case threadParticipants = "thread_participants"
        
        case user
        
        case html
        
        case mml
        
        case shadowed
        
        case cid
        
        case pinnedBy = "pinned_by"
        
        case replyCount = "reply_count"
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case latestReactions = "latest_reactions"
        
        case pinExpires = "pin_expires"
        
        case pinned
        
        case pinnedAt = "pinned_at"
        
        case quotedMessageId = "quoted_message_id"
        
        case deletedAt = "deleted_at"
        
        case parentId = "parent_id"
        
        case silent
        
        case command
        
        case quotedMessage = "quoted_message"
        
        case reactionCounts = "reaction_counts"
        
        case showInChannel = "show_in_channel"
        
        case custom
        
        case i18n
        
        case ownReactions = "own_reactions"
        
        case attachments
        
        case id
        
        case reactionScores = "reaction_scores"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(type, forKey: .type)
    }
}
