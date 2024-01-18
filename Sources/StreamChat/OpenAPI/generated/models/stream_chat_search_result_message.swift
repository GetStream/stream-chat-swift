//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResultMessage: Codable, Hashable {
    public var custom: [String: RawJSON]
    
    public var deletedReplyCount: Int
    
    public var reactionCounts: [String: RawJSON]
    
    public var showInChannel: Bool?
    
    public var silent: Bool
    
    public var pinned: Bool
    
    public var pinnedAt: Date?
    
    public var text: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var id: String
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var ownReactions: [StreamChatReaction?]
    
    public var attachments: [StreamChatAttachment?]
    
    public var imageLabels: [String: RawJSON]?
    
    public var mml: String?
    
    public var pinnedBy: StreamChatUserObject?
    
    public var replyCount: Int
    
    public var html: String
    
    public var i18n: [String: RawJSON]?
    
    public var type: String
    
    public var command: String?
    
    public var latestReactions: [StreamChatReaction?]
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var updatedAt: Date
    
    public var beforeMessageSendFailed: Bool?
    
    public var deletedAt: Date?
    
    public var pinExpires: Date?
    
    public var quotedMessageId: String?
    
    public var shadowed: Bool
    
    public var channel: StreamChatChannelResponse?
    
    public var cid: String
    
    public var parentId: String?
    
    public var quotedMessage: StreamChatMessage?
    
    public var reactionScores: [String: RawJSON]
    
    public init(custom: [String: RawJSON], deletedReplyCount: Int, reactionCounts: [String: RawJSON], showInChannel: Bool?, silent: Bool, pinned: Bool, pinnedAt: Date?, text: String, user: StreamChatUserObject?, createdAt: Date, id: String, mentionedUsers: [StreamChatUserObject], ownReactions: [StreamChatReaction?], attachments: [StreamChatAttachment?], imageLabels: [String: RawJSON]?, mml: String?, pinnedBy: StreamChatUserObject?, replyCount: Int, html: String, i18n: [String: RawJSON]?, type: String, command: String?, latestReactions: [StreamChatReaction?], threadParticipants: [StreamChatUserObject]?, updatedAt: Date, beforeMessageSendFailed: Bool?, deletedAt: Date?, pinExpires: Date?, quotedMessageId: String?, shadowed: Bool, channel: StreamChatChannelResponse?, cid: String, parentId: String?, quotedMessage: StreamChatMessage?, reactionScores: [String: RawJSON]) {
        self.custom = custom
        
        self.deletedReplyCount = deletedReplyCount
        
        self.reactionCounts = reactionCounts
        
        self.showInChannel = showInChannel
        
        self.silent = silent
        
        self.pinned = pinned
        
        self.pinnedAt = pinnedAt
        
        self.text = text
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.id = id
        
        self.mentionedUsers = mentionedUsers
        
        self.ownReactions = ownReactions
        
        self.attachments = attachments
        
        self.imageLabels = imageLabels
        
        self.mml = mml
        
        self.pinnedBy = pinnedBy
        
        self.replyCount = replyCount
        
        self.html = html
        
        self.i18n = i18n
        
        self.type = type
        
        self.command = command
        
        self.latestReactions = latestReactions
        
        self.threadParticipants = threadParticipants
        
        self.updatedAt = updatedAt
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.deletedAt = deletedAt
        
        self.pinExpires = pinExpires
        
        self.quotedMessageId = quotedMessageId
        
        self.shadowed = shadowed
        
        self.channel = channel
        
        self.cid = cid
        
        self.parentId = parentId
        
        self.quotedMessage = quotedMessage
        
        self.reactionScores = reactionScores
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom = "Custom"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case reactionCounts = "reaction_counts"
        
        case showInChannel = "show_in_channel"
        
        case silent
        
        case pinned
        
        case pinnedAt = "pinned_at"
        
        case text
        
        case user
        
        case createdAt = "created_at"
        
        case id
        
        case mentionedUsers = "mentioned_users"
        
        case ownReactions = "own_reactions"
        
        case attachments
        
        case imageLabels = "image_labels"
        
        case mml
        
        case pinnedBy = "pinned_by"
        
        case replyCount = "reply_count"
        
        case html
        
        case i18n
        
        case type
        
        case command
        
        case latestReactions = "latest_reactions"
        
        case threadParticipants = "thread_participants"
        
        case updatedAt = "updated_at"
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case deletedAt = "deleted_at"
        
        case pinExpires = "pin_expires"
        
        case quotedMessageId = "quoted_message_id"
        
        case shadowed
        
        case channel
        
        case cid
        
        case parentId = "parent_id"
        
        case quotedMessage = "quoted_message"
        
        case reactionScores = "reaction_scores"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(reactionScores, forKey: .reactionScores)
    }
}
