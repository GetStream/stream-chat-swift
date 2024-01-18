//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelHiddenEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var clearHistory: Bool
    
    public var createdAt: Date
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public init(cid: String, clearHistory: Bool, createdAt: Date, type: String, user: StreamChatUserObject?, channel: StreamChatChannelResponse?, channelId: String, channelType: String) {
        self.cid = cid
        
        self.clearHistory = clearHistory
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case clearHistory = "clear_history"
        
        case createdAt = "created_at"
        
        case type
        
        case user
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(clearHistory, forKey: .clearHistory)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}
