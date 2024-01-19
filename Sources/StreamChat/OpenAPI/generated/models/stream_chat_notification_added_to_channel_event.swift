//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationAddedToChannelEvent: Codable, Hashable, Event {
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var member: StreamChatChannelMember?
    
    public var type: String
    
    public init(channel: StreamChatChannelResponse?, channelId: String, channelType: String, cid: String, createdAt: Date, member: StreamChatChannelMember?, type: String) {
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.member = member
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case member
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(member, forKey: .member)
        
        try container.encode(type, forKey: .type)
    }
}