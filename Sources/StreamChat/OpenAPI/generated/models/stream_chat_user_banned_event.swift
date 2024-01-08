//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable {
    public var channelId: String
    
    public var channelType: String
    
    public var reason: String?
    
    public var team: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var cid: String
    
    public var createdAt: String
    
    public var createdBy: StreamChatUserObject
    
    public var expiration: String?
    
    public var shadow: Bool
    
    public init(channelId: String, channelType: String, reason: String?, team: String?, type: String, user: StreamChatUserObject?, cid: String, createdAt: String, createdBy: StreamChatUserObject, expiration: String?, shadow: Bool) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.reason = reason
        
        self.team = team
        
        self.type = type
        
        self.user = user
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.createdBy = createdBy
        
        self.expiration = expiration
        
        self.shadow = shadow
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case reason
        
        case team
        
        case type
        
        case user
        
        case cid
        
        case createdAt = "created_at"
        
        case createdBy = "created_by"
        
        case expiration
        
        case shadow
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(shadow, forKey: .shadow)
    }
}
