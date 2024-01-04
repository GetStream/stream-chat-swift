//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable {
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: String
    
    public var createdBy: StreamChatUserObject
    
    public var reason: String?
    
    public var shadow: Bool
    
    public var team: String?
    
    public var cid: String
    
    public var expiration: String?
    
    public var type: String
    
    public init(user: StreamChatUserObject?, channelId: String, channelType: String, createdAt: String, createdBy: StreamChatUserObject, reason: String?, shadow: Bool, team: String?, cid: String, expiration: String?, type: String) {
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.createdBy = createdBy
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.team = team
        
        self.cid = cid
        
        self.expiration = expiration
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case createdBy = "created_by"
        
        case reason
        
        case shadow
        
        case team
        
        case cid
        
        case expiration
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(type, forKey: .type)
    }
}
