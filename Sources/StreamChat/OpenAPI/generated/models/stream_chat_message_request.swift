//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageRequest: Codable, Hashable {
    public var pinExpires: Date?
    
    public var pinned: Bool?
    
    public var quotedMessageId: String?
    
    public var custom: [String: RawJSON]?
    
    public var silent: Bool?
    
    public var text: String?
    
    public var id: String?
    
    public var type: String?
    
    public var attachments: [StreamChatAttachmentRequest?]
    
    public var mentionedUsers: [String]?
    
    public var parentId: String?
    
    public var pinnedAt: Date?
    
    public var showInChannel: Bool?
    
    public init(pinExpires: Date?, pinned: Bool?, quotedMessageId: String?, custom: [String: RawJSON]?, silent: Bool?, text: String?, id: String?, type: String?, attachments: [StreamChatAttachmentRequest?], mentionedUsers: [String]?, parentId: String?, pinnedAt: Date?, showInChannel: Bool?) {
        self.pinExpires = pinExpires
        
        self.pinned = pinned
        
        self.quotedMessageId = quotedMessageId
        
        self.custom = custom
        
        self.silent = silent
        
        self.text = text
        
        self.id = id
        
        self.type = type
        
        self.attachments = attachments
        
        self.mentionedUsers = mentionedUsers
        
        self.parentId = parentId
        
        self.pinnedAt = pinnedAt
        
        self.showInChannel = showInChannel
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pinExpires = "pin_expires"
        
        case pinned
        
        case quotedMessageId = "quoted_message_id"
        
        case custom
        
        case silent
        
        case text
        
        case id
        
        case type
        
        case attachments
        
        case mentionedUsers = "mentioned_users"
        
        case parentId = "parent_id"
        
        case pinnedAt = "pinned_at"
        
        case showInChannel = "show_in_channel"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(showInChannel, forKey: .showInChannel)
    }
}
