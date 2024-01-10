//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageRequest: Codable, Hashable {
    public var type: String?
    
    public var id: String?
    
    public var parentId: String?
    
    public var showInChannel: Bool?
    
    public var custom: [String: RawJSON]?
    
    public var mentionedUsers: [String]?
    
    public var quotedMessageId: String?
    
    public var silent: Bool?
    
    public var text: String?
    
    public var attachments: [StreamChatAttachmentRequest?]
    
    public var pinned: Bool?
    
    public var pinnedAt: String?
    
    public var pinExpires: String?
    
    public init(type: String?, id: String?, parentId: String?, showInChannel: Bool?, custom: [String: RawJSON]?, mentionedUsers: [String]?, quotedMessageId: String?, silent: Bool?, text: String?, attachments: [StreamChatAttachmentRequest?], pinned: Bool?, pinnedAt: String?, pinExpires: String?) {
        self.type = type
        
        self.id = id
        
        self.parentId = parentId
        
        self.showInChannel = showInChannel
        
        self.custom = custom
        
        self.mentionedUsers = mentionedUsers
        
        self.quotedMessageId = quotedMessageId
        
        self.silent = silent
        
        self.text = text
        
        self.attachments = attachments
        
        self.pinned = pinned
        
        self.pinnedAt = pinnedAt
        
        self.pinExpires = pinExpires
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case id
        
        case parentId = "parent_id"
        
        case showInChannel = "show_in_channel"
        
        case custom
        
        case mentionedUsers = "mentioned_users"
        
        case quotedMessageId = "quoted_message_id"
        
        case silent
        
        case text
        
        case attachments
        
        case pinned
        
        case pinnedAt = "pinned_at"
        
        case pinExpires = "pin_expires"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(pinExpires, forKey: .pinExpires)
    }
}
