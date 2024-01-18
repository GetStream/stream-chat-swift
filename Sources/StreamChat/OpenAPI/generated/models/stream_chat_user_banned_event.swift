//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var createdBy: StreamChatUserObject
    
    public var expiration: Date?
    
    public var shadow: Bool
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var reason: String?
    
    public var team: String?
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, createdBy: StreamChatUserObject, expiration: Date?, shadow: Bool, type: String, user: StreamChatUserObject?, reason: String?, team: String?) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.createdBy = createdBy
        
        self.expiration = expiration
        
        self.shadow = shadow
        
        self.type = type
        
        self.user = user
        
        self.reason = reason
        
        self.team = team
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case createdBy = "created_by"
        
        case expiration
        
        case shadow
        
        case type
        
        case user
        
        case reason
        
        case team
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(shadow, forKey: .shadow)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(team, forKey: .team)
    }
}
