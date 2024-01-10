//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationChannelTruncatedEvent: Codable, Hashable {
    public var cid: String
    
    public var createdAt: String
    
    public var type: String
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public init(cid: String, createdAt: String, type: String, channel: StreamChatChannelResponse?, channelId: String, channelType: String) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case type
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}
