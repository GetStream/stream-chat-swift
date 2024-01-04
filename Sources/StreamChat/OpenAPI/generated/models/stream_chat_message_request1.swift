//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageRequest1: Codable, Hashable {
    public var id: String?
    
    public var pinExpires: String?
    
    public var pinned: Bool?
    
    public var quotedMessageId: String?
    
    public var silent: Bool?
    
    public var text: String?
    
    public var attachments: [StreamChatAttachmentRequest?]
    
    public var mentionedUsers: [String]?
    
    public var type: String?
    
    public var parentId: String?
    
    public var pinnedAt: String?
    
    public var custom: [String: RawJSON]?
    
    public var showInChannel: Bool?
    
    public init(id: String?, pinExpires: String?, pinned: Bool?, quotedMessageId: String?, silent: Bool?, text: String?, attachments: [StreamChatAttachmentRequest?], mentionedUsers: [String]?, type: String?, parentId: String?, pinnedAt: String?, custom: [String: RawJSON]?, showInChannel: Bool?) {
        self.id = id
        
        self.pinExpires = pinExpires
        
        self.pinned = pinned
        
        self.quotedMessageId = quotedMessageId
        
        self.silent = silent
        
        self.text = text
        
        self.attachments = attachments
        
        self.mentionedUsers = mentionedUsers
        
        self.type = type
        
        self.parentId = parentId
        
        self.pinnedAt = pinnedAt
        
        self.custom = custom
        
        self.showInChannel = showInChannel
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case pinExpires = "pin_expires"
        
        case pinned
        
        case quotedMessageId = "quoted_message_id"
        
        case silent
        
        case text
        
        case attachments
        
        case mentionedUsers = "mentioned_users"
        
        case type
        
        case parentId = "parent_id"
        
        case pinnedAt = "pinned_at"
        
        case custom
        
        case showInChannel = "show_in_channel"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(showInChannel, forKey: .showInChannel)
    }
}
