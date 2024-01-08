//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResultMessage: Codable, Hashable {
    public var quotedMessage: StreamChatMessage?
    
    public var updatedAt: String
    
    public var user: StreamChatUserObject?
    
    public var beforeMessageSendFailed: Bool?
    
    public var pinned: Bool
    
    public var reactionScores: [String: RawJSON]
    
    public var text: String
    
    public var command: String?
    
    public var latestReactions: [StreamChatReaction?]
    
    public var html: String
    
    public var parentId: String?
    
    public var id: String
    
    public var silent: Bool
    
    public var attachments: [StreamChatAttachment?]
    
    public var i18n: [String: RawJSON]?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var custom: [String: RawJSON]
    
    public var createdAt: String
    
    public var ownReactions: [StreamChatReaction?]
    
    public var quotedMessageId: String?
    
    public var replyCount: Int
    
    public var shadowed: Bool
    
    public var showInChannel: Bool?
    
    public var deletedAt: String?
    
    public var imageLabels: [String: RawJSON]?
    
    public var mml: String?
    
    public var pinExpires: String?
    
    public var pinnedAt: String?
    
    public var pinnedBy: StreamChatUserObject?
    
    public var reactionCounts: [String: RawJSON]
    
    public var cid: String
    
    public var mentionedUsers: [StreamChatUserObject]
    
    public var channel: StreamChatChannelResponse?
    
    public var deletedReplyCount: Int
    
    public init(quotedMessage: StreamChatMessage?, updatedAt: String, user: StreamChatUserObject?, beforeMessageSendFailed: Bool?, pinned: Bool, reactionScores: [String: RawJSON], text: String, command: String?, latestReactions: [StreamChatReaction?], html: String, parentId: String?, id: String, silent: Bool, attachments: [StreamChatAttachment?], i18n: [String: RawJSON]?, threadParticipants: [StreamChatUserObject]?, type: String, custom: [String: RawJSON], createdAt: String, ownReactions: [StreamChatReaction?], quotedMessageId: String?, replyCount: Int, shadowed: Bool, showInChannel: Bool?, deletedAt: String?, imageLabels: [String: RawJSON]?, mml: String?, pinExpires: String?, pinnedAt: String?, pinnedBy: StreamChatUserObject?, reactionCounts: [String: RawJSON], cid: String, mentionedUsers: [StreamChatUserObject], channel: StreamChatChannelResponse?, deletedReplyCount: Int) {
        self.quotedMessage = quotedMessage
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.pinned = pinned
        
        self.reactionScores = reactionScores
        
        self.text = text
        
        self.command = command
        
        self.latestReactions = latestReactions
        
        self.html = html
        
        self.parentId = parentId
        
        self.id = id
        
        self.silent = silent
        
        self.attachments = attachments
        
        self.i18n = i18n
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.ownReactions = ownReactions
        
        self.quotedMessageId = quotedMessageId
        
        self.replyCount = replyCount
        
        self.shadowed = shadowed
        
        self.showInChannel = showInChannel
        
        self.deletedAt = deletedAt
        
        self.imageLabels = imageLabels
        
        self.mml = mml
        
        self.pinExpires = pinExpires
        
        self.pinnedAt = pinnedAt
        
        self.pinnedBy = pinnedBy
        
        self.reactionCounts = reactionCounts
        
        self.cid = cid
        
        self.mentionedUsers = mentionedUsers
        
        self.channel = channel
        
        self.deletedReplyCount = deletedReplyCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case quotedMessage = "quoted_message"
        
        case updatedAt = "updated_at"
        
        case user
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case pinned
        
        case reactionScores = "reaction_scores"
        
        case text
        
        case command
        
        case latestReactions = "latest_reactions"
        
        case html
        
        case parentId = "parent_id"
        
        case id
        
        case silent
        
        case attachments
        
        case i18n
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case ownReactions = "own_reactions"
        
        case quotedMessageId = "quoted_message_id"
        
        case replyCount = "reply_count"
        
        case shadowed
        
        case showInChannel = "show_in_channel"
        
        case deletedAt = "deleted_at"
        
        case imageLabels = "image_labels"
        
        case mml
        
        case pinExpires = "pin_expires"
        
        case pinnedAt = "pinned_at"
        
        case pinnedBy = "pinned_by"
        
        case reactionCounts = "reaction_counts"
        
        case cid
        
        case mentionedUsers = "mentioned_users"
        
        case channel
        
        case deletedReplyCount = "deleted_reply_count"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(reactionScores, forKey: .reactionScores)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
    }
}
