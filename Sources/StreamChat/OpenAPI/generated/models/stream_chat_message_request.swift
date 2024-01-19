//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageRequest: Codable, Hashable {
    public var attachments: [StreamChatAttachmentRequest?]
    
    public var custom: [String: RawJSON]?
    
    public var parentId: String?
    
    public var pinExpires: Date?
    
    public var pinned: Bool?
    
    public var pinnedAt: Date?
    
    public var showInChannel: Bool?
    
    public var id: String?
    
    public var quotedMessageId: String?
    
    public var text: String?
    
    public var mentionedUsers: [String]?
    
    public var silent: Bool?
    
    public var type: String?
    
    public init(attachments: [StreamChatAttachmentRequest?], custom: [String: RawJSON]?, parentId: String?, pinExpires: Date?, pinned: Bool?, pinnedAt: Date?, showInChannel: Bool?, id: String?, quotedMessageId: String?, text: String?, mentionedUsers: [String]?, silent: Bool?, type: String?) {
        self.attachments = attachments
        
        self.custom = custom
        
        self.parentId = parentId
        
        self.pinExpires = pinExpires
        
        self.pinned = pinned
        
        self.pinnedAt = pinnedAt
        
        self.showInChannel = showInChannel
        
        self.id = id
        
        self.quotedMessageId = quotedMessageId
        
        self.text = text
        
        self.mentionedUsers = mentionedUsers
        
        self.silent = silent
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        
        case custom
        
        case parentId = "parent_id"
        
        case pinExpires = "pin_expires"
        
        case pinned
        
        case pinnedAt = "pinned_at"
        
        case showInChannel = "show_in_channel"
        
        case id
        
        case quotedMessageId = "quoted_message_id"
        
        case text
        
        case mentionedUsers = "mentioned_users"
        
        case silent
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(type, forKey: .type)
    }
}
