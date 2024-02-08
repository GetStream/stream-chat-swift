//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserBannedEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var shadow: Bool
    
    public var type: String
    
    public var createdBy: StreamChatUserObject
    
    public var expiration: Date? = nil
    
    public var reason: String? = nil
    
    public var team: String? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, shadow: Bool, type: String, createdBy: StreamChatUserObject, expiration: Date? = nil, reason: String? = nil, team: String? = nil, user: StreamChatUserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.shadow = shadow
        
        self.type = type
        
        self.createdBy = createdBy
        
        self.expiration = expiration
        
        self.reason = reason
        
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
        
        case createdBy = "created_by"
        
        case expiration
        
        case reason
        
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
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(expiration, forKey: .expiration)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
    }
}

extension StreamChatUserBannedEvent: EventContainsCreationDate {}

extension StreamChatUserBannedEvent: EventContainsUser {}
