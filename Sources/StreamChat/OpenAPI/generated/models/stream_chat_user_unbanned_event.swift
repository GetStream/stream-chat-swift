//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserUnbannedEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var shadow: Bool
    
    public var type: String
    
    public var team: String? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, shadow: Bool, type: String, team: String? = nil, user: StreamChatUserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.shadow = shadow
        
        self.type = type
        
        self.team = team
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case shadow
        
        case type
        
        case team
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
    }
}
