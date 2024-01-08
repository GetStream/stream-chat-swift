//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTypingStopEvent: Codable, Hashable {
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var parentId: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public init(channelType: String, cid: String, createdAt: String, parentId: String?, type: String, user: StreamChatUserObject?, channelId: String) {
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.parentId = parentId
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case parentId = "parent_id"
        
        case type
        
        case user
        
        case channelId = "channel_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
    }
}
