//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    
    public var reason: String?
    
    public var shadow: Bool
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var type: String
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdBy: StreamChatUserObject
    
    public var expiration: Date?
    
    public init(createdAt: Date, reason: String?, shadow: Bool, team: String?, user: StreamChatUserObject?, type: String, channelId: String, channelType: String, cid: String, createdBy: StreamChatUserObject, expiration: Date?) {
        self.createdAt = createdAt
        
        self.reason = reason
        
        self.shadow = shadow
        
        self.team = team
        
        self.user = user
        
        self.type = type
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdBy = createdBy
        
        self.expiration = expiration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case reason
        
        case shadow
        
        case team
        
        case user
        
        case type
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdBy = "created_by"
        
        case expiration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(expiration, forKey: .expiration)
    }
}
