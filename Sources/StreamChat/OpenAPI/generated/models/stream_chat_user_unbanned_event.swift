//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserUnbannedEvent: Codable, Hashable {
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var shadow: Bool
    
    public var team: String?
    
    public var type: String
    
    public init(user: StreamChatUserObject?, channelId: String, channelType: String, cid: String, createdAt: String, shadow: Bool, team: String?, type: String) {
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.shadow = shadow
        
        self.team = team
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case shadow
        
        case team
        
        case type
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
    }
}
