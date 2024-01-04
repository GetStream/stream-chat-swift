//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class StreamChatMessageRequest2: Codable, Hashable {
    public static func == (lhs: StreamChatMessageRequest2, rhs: StreamChatMessageRequest2) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var parentId: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public var deletedAt: String?
    
    public var deletedReplyCount: Int?
    
    public var ownReactions: [StreamChatReactionRequest?]?
    
    public var text: String
    
    public var custom: [String: RawJSON]?
    
    public var quotedMessageId: String?
    
    public var reactionCounts: [String: RawJSON]?
    
    public var threadParticipants: [StreamChatUserObjectRequest?]?
    
    public var createdAt: String?
    
    public var i18n: [String: RawJSON]?
    
    public var pinnedBy: StreamChatUserObjectRequest?
    
    public var command: String?
    
    public var id: String?
    
    public var imageLabels: [String: RawJSON]?
    
    public var latestReactions: [StreamChatReactionRequest?]?
    
    public var mentionedUsers: [StreamChatUserObjectRequest?]?
    
    public var attachments: [StreamChatAttachmentRequest?]?
    
    public var beforeMessageSendFailed: Bool?
    
    public var cid: String?
    
    public var pinExpires: String?
    
    public var replyCount: Int?
    
    public var shadowed: Bool?
    
    public var pinned: Bool?
    
    public var quotedMessage: StreamChatMessageRequest2?
    
    public var type: String?
    
    public var updatedAt: String?
    
    public var silent: Bool?
    
    public var html: String?
    
    public var pinnedAt: String?
    
    public var showInChannel: Bool?
    
    public var mml: String
    
    public var reactionScores: [String: RawJSON]?
    
    public init(parentId: String?, user: StreamChatUserObjectRequest?, deletedAt: String?, deletedReplyCount: Int?, ownReactions: [StreamChatReactionRequest?]?, text: String, custom: [String: RawJSON]?, quotedMessageId: String?, reactionCounts: [String: RawJSON]?, threadParticipants: [StreamChatUserObjectRequest?]?, createdAt: String?, i18n: [String: RawJSON]?, pinnedBy: StreamChatUserObjectRequest?, command: String?, id: String?, imageLabels: [String: RawJSON]?, latestReactions: [StreamChatReactionRequest?]?, mentionedUsers: [StreamChatUserObjectRequest?]?, attachments: [StreamChatAttachmentRequest?]?, beforeMessageSendFailed: Bool?, cid: String?, pinExpires: String?, replyCount: Int?, shadowed: Bool?, pinned: Bool?, quotedMessage: StreamChatMessageRequest2?, type: String?, updatedAt: String?, silent: Bool?, html: String?, pinnedAt: String?, showInChannel: Bool?, mml: String, reactionScores: [String: RawJSON]?) {
        self.parentId = parentId
        
        self.user = user
        
        self.deletedAt = deletedAt
        
        self.deletedReplyCount = deletedReplyCount
        
        self.ownReactions = ownReactions
        
        self.text = text
        
        self.custom = custom
        
        self.quotedMessageId = quotedMessageId
        
        self.reactionCounts = reactionCounts
        
        self.threadParticipants = threadParticipants
        
        self.createdAt = createdAt
        
        self.i18n = i18n
        
        self.pinnedBy = pinnedBy
        
        self.command = command
        
        self.id = id
        
        self.imageLabels = imageLabels
        
        self.latestReactions = latestReactions
        
        self.mentionedUsers = mentionedUsers
        
        self.attachments = attachments
        
        self.beforeMessageSendFailed = beforeMessageSendFailed
        
        self.cid = cid
        
        self.pinExpires = pinExpires
        
        self.replyCount = replyCount
        
        self.shadowed = shadowed
        
        self.pinned = pinned
        
        self.quotedMessage = quotedMessage
        
        self.type = type
        
        self.updatedAt = updatedAt
        
        self.silent = silent
        
        self.html = html
        
        self.pinnedAt = pinnedAt
        
        self.showInChannel = showInChannel
        
        self.mml = mml
        
        self.reactionScores = reactionScores
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case parentId = "parent_id"
        
        case user
        
        case deletedAt = "deleted_at"
        
        case deletedReplyCount = "deleted_reply_count"
        
        case ownReactions = "own_reactions"
        
        case text
        
        case custom = "Custom"
        
        case quotedMessageId = "quoted_message_id"
        
        case reactionCounts = "reaction_counts"
        
        case threadParticipants = "thread_participants"
        
        case createdAt = "created_at"
        
        case i18n
        
        case pinnedBy = "pinned_by"
        
        case command
        
        case id
        
        case imageLabels = "image_labels"
        
        case latestReactions = "latest_reactions"
        
        case mentionedUsers = "mentioned_users"
        
        case attachments
        
        case beforeMessageSendFailed = "before_message_send_failed"
        
        case cid
        
        case pinExpires = "pin_expires"
        
        case replyCount = "reply_count"
        
        case shadowed
        
        case pinned
        
        case quotedMessage = "quoted_message"
        
        case type
        
        case updatedAt = "updated_at"
        
        case silent
        
        case html
        
        case pinnedAt = "pinned_at"
        
        case showInChannel = "show_in_channel"
        
        case mml
        
        case reactionScores = "reaction_scores"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(deletedReplyCount, forKey: .deletedReplyCount)
        
        try container.encode(ownReactions, forKey: .ownReactions)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(reactionCounts, forKey: .reactionCounts)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(i18n, forKey: .i18n)
        
        try container.encode(pinnedBy, forKey: .pinnedBy)
        
        try container.encode(command, forKey: .command)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(latestReactions, forKey: .latestReactions)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(beforeMessageSendFailed, forKey: .beforeMessageSendFailed)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(replyCount, forKey: .replyCount)
        
        try container.encode(shadowed, forKey: .shadowed)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(quotedMessage, forKey: .quotedMessage)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(reactionScores, forKey: .reactionScores)
    }
}
