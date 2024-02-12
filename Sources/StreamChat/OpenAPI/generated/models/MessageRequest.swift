//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageRequest: Codable, Hashable {
    public var attachments: [AttachmentRequest?]
    
    public var id: String? = nil
    
    public var parentId: String? = nil
    
    public var pinExpires: Date? = nil
    
    public var pinned: Bool? = nil
    
    public var pinnedAt: Date? = nil
    
    public var quotedMessageId: String? = nil
    
    public var showInChannel: Bool? = nil
    
    public var silent: Bool? = nil
    
    public var text: String? = nil
    
    public var type: String? = nil
    
    public var mentionedUsers: [String]? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public init(attachments: [AttachmentRequest?], id: String? = nil, parentId: String? = nil, pinExpires: Date? = nil, pinned: Bool? = nil, pinnedAt: Date? = nil, quotedMessageId: String? = nil, showInChannel: Bool? = nil, silent: Bool? = nil, text: String? = nil, type: String? = nil, mentionedUsers: [String]? = nil, custom: [String: RawJSON]? = nil) {
        self.attachments = attachments
        
        self.id = id
        
        self.parentId = parentId
        
        self.pinExpires = pinExpires
        
        self.pinned = pinned
        
        self.pinnedAt = pinnedAt
        
        self.quotedMessageId = quotedMessageId
        
        self.showInChannel = showInChannel
        
        self.silent = silent
        
        self.text = text
        
        self.type = type
        
        self.mentionedUsers = mentionedUsers
        
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        
        case id
        
        case parentId = "parent_id"
        
        case pinExpires = "pin_expires"
        
        case pinned
        
        case pinnedAt = "pinned_at"
        
        case quotedMessageId = "quoted_message_id"
        
        case showInChannel = "show_in_channel"
        
        case silent
        
        case text
        
        case type
        
        case mentionedUsers = "mentioned_users"
        
        case custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(attachments, forKey: .attachments)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(pinExpires, forKey: .pinExpires)
        
        try container.encode(pinned, forKey: .pinned)
        
        try container.encode(pinnedAt, forKey: .pinnedAt)
        
        try container.encode(quotedMessageId, forKey: .quotedMessageId)
        
        try container.encode(showInChannel, forKey: .showInChannel)
        
        try container.encode(silent, forKey: .silent)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(mentionedUsers, forKey: .mentionedUsers)
        
        try container.encode(custom, forKey: .custom)
    }
}
