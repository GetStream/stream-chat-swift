//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelUpdatedEvent: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var user: StreamChatUserObject?
    
    public var type: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public init(channel: StreamChatChannelResponse?, channelId: String, channelType: String, user: StreamChatUserObject?, type: String, cid: String, createdAt: String, message: StreamChatMessage?, team: String?) {
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.user = user
        
        self.type = type
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case user
        
        case type
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case team
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
    }
}
