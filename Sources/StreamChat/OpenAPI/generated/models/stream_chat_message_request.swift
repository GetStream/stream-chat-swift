//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageRequest: Codable, Hashable {
    public var userId: String?
    
    public var id: String?
    
    public var pinned: Bool?
    
    public var pinnedAt: String?
    
    public var showInChannel: Bool?
    
    public var text: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public var custom: [String: RawJSON]?
    
    public var html: String?
    
    public var parentId: String?
    
    public var silent: Bool?
    
    public var attachments: [StreamChatAttachmentRequest?]
    
    public var mentionedUsers: [String]?
    
    public var quotedMessageId: String?
    
    public var mml: String?
    
    public var pinExpires: String?
    
    public var type: String?
    
    public init(userId: String?, id: String?, pinned: Bool?, pinnedAt: String?, showInChannel: Bool?, text: String?, user: StreamChatUserObjectRequest?, custom: [String: RawJSON]?, html: String?, parentId: String?, silent: Bool?, attachments: [StreamChatAttachmentRequest?], mentionedUsers: [String]?, quotedMessageId: String?, mml: String?, pinExpires: String?, type: String?) {
        self.userId = userId
        
        self.id = id
        
        self.pinned = pinned
        
        self.pinnedAt = pinnedAt
        
        self.showInChannel = showInChannel
        
        self.text = text
        
        self.user = user
        
        self.custom = custom
        
        self.html = html
        
        self.parentId = parentId
        
        self.silent = silent
        
        self.attachments = attachments
        
        self.mentionedUsers = mentionedUsers
        
        self.quotedMessageId = quotedMessageId
        
        self.mml = mml
        
        self.pinExpires = pinExpires
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case id
        
        case pinned
        
        case pinnedAt = "pinned_at"
        
        case showInChannel = "show_in_channel"
        
        case text
        
        case user
        
        case custom
        
        case html
        
        case parentId = "parent_id"
        
        case silent
        
        case attachments
        
        case mentionedUsers = "mentioned_users"
        
        case quotedMessageId = "quoted_message_id"
        
        case mml
        
        case pinExpires = "pin_expires"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(html, forKey: .html)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(mml, forKey: .mml)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(type, forKey: .type)
    }
}
