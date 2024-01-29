//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelHiddenEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var clearHistory: Bool
    
    public var createdAt: Date
    
    public var type: String
    
    public var channel: StreamChatChannelResponse? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, clearHistory: Bool, createdAt: Date, type: String, channel: StreamChatChannelResponse? = nil, user: StreamChatUserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.clearHistory = clearHistory
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.channel = channel
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case clearHistory = "clear_history"
        
        case createdAt = "created_at"
        
        case type
        
        case channel
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(clearHistory, forKey: .clearHistory)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(user, forKey: .user)
    }
}

extension StreamChatChannelHiddenEvent: EventContainsChannel {}

extension StreamChatChannelHiddenEvent: EventContainsUser {}
