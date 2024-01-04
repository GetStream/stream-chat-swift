//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTypingStartEvent: Codable, Hashable {
    public var createdAt: String
    
    public var parentId: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public init(createdAt: String, parentId: String?, type: String, user: StreamChatUserObject?, channelId: String, channelType: String, cid: String) {
        self.createdAt = createdAt
        
        self.parentId = parentId
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case parentId = "parent_id"
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
    }
}
