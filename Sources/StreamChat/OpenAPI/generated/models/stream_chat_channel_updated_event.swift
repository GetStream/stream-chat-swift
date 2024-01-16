//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelUpdatedEvent: Codable, Hashable, Event {
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var cid: String
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public init(type: String, user: StreamChatUserObject?, createdAt: String, message: StreamChatMessage?, team: String?, cid: String, channel: StreamChatChannelResponse?, channelId: String, channelType: String) {
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.cid = cid
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case cid
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}
