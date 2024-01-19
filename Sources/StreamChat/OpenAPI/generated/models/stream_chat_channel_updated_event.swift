//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelUpdatedEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var type: String
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public init(cid: String, team: String?, user: StreamChatUserObject?, createdAt: Date, message: StreamChatMessage?, type: String, channel: StreamChatChannelResponse?, channelId: String, channelType: String) {
        self.cid = cid
        
        self.team = team
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.type = type
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case team
        
        case user
        
        case createdAt = "created_at"
        
        case message
        
        case type
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}