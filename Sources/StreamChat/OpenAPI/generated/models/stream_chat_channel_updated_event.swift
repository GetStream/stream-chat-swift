//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelUpdatedEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: Date
    
    public var message: StreamChatMessage?
    
    public var type: String
    
    public init(cid: String, team: String?, user: StreamChatUserObject?, channel: StreamChatChannelResponse?, channelId: String, channelType: String, createdAt: Date, message: StreamChatMessage?, type: String) {
        self.cid = cid
        
        self.team = team
        
        self.user = user
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case team
        
        case user
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case message
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(type, forKey: .type)
    }
}
