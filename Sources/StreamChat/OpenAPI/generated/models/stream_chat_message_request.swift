//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageRequest: Codable, Hashable {
    public var attachments: [StreamChatAttachmentRequest?]
    
    public var parentId: String?
    
    public var showInChannel: Bool?
    
    public var silent: Bool?
    
    public var custom: [String: RawJSON]?
    
    public var pinnedAt: String?
    
    public var quotedMessageId: String?
    
    public var id: String?
    
    public var mentionedUsers: [String]?
    
    public var pinned: Bool?
    
    public var type: String?
    
    public var pinExpires: String?
    
    public var text: String?
    
    public init(attachments: [StreamChatAttachmentRequest?], parentId: String?, showInChannel: Bool?, silent: Bool?, custom: [String: RawJSON]?, pinnedAt: String?, quotedMessageId: String?, id: String?, mentionedUsers: [String]?, pinned: Bool?, type: String?, pinExpires: String?, text: String?) {
        self.attachments = attachments
        
        self.parentId = parentId
        
        self.showInChannel = showInChannel
        
        self.silent = silent
        
        self.custom = custom
        
        self.pinnedAt = pinnedAt
        
        self.quotedMessageId = quotedMessageId
        
        self.id = id
        
        self.mentionedUsers = mentionedUsers
        
        self.pinned = pinned
        
        self.type = type
        
        self.pinExpires = pinExpires
        
        self.text = text
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        
        case parentId = "parent_id"
        
        case showInChannel = "show_in_channel"
        
        case silent
        
        case custom
        
        case pinnedAt = "pinned_at"
        
        case quotedMessageId = "quoted_message_id"
        
        case id
        
        case mentionedUsers = "mentioned_users"
        
        case pinned
        
        case type
        
        case pinExpires = "pin_expires"
        
        case text
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(text, forKey: .text)
    }
}
