//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelUpdatedEvent: Codable, Hashable {
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var team: String?
    
    public var type: String
    
    public var channel: StreamChatChannelResponse?
    
    public var channelType: String
    
    public init(user: StreamChatUserObject?, channelId: String, cid: String, createdAt: String, message: StreamChatMessage?, team: String?, type: String, channel: StreamChatChannelResponse?, channelType: String) {
        self.user = user
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.team = team
        
        self.type = type
        
        self.channel = channel
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case team
        
        case type
        
        case channel
        
        case channelType = "channel_type"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelType, forKey: .channelType)
    }
}
