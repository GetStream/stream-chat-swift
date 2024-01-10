//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var expiration: String?
    
    public var shadow: Bool
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdBy: StreamChatUserObject
    
    public var reason: String?
    
    public var team: String?
    
    public var type: String
    
    public init(createdAt: String, expiration: String?, shadow: Bool, user: StreamChatUserObject?, channelId: String, channelType: String, cid: String, createdBy: StreamChatUserObject, reason: String?, team: String?, type: String) {
        self.createdAt = createdAt
        
        self.expiration = expiration
        
        self.shadow = shadow
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdBy = createdBy
        
        self.reason = reason
        
        self.team = team
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case expiration
        
        case shadow
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdBy = "created_by"
        
        case reason
        
        case team
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
    }
}
