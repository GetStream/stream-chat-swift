//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable, Event {
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var reason: String?
    
    public var shadow: Bool
    
    public var team: String?
    
    public var channelType: String
    
    public var createdBy: StreamChatUserObject
    
    public var expiration: String?
    
    public init(type: String, user: StreamChatUserObject?, channelId: String, cid: String, createdAt: String, reason: String?, shadow: Bool, team: String?, channelType: String, createdBy: StreamChatUserObject, expiration: String?) {
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.team = team
        
        self.channelType = channelType
        
        self.createdBy = createdBy
        
        self.expiration = expiration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
        
        case reason
        
        case shadow
        
        case team
        
        case channelType = "channel_type"
        
        case createdBy = "created_by"
        
        case expiration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(expiration, forKey: .expiration)
    }
}
