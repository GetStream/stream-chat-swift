//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelHiddenEvent: Codable, Hashable {
    public var clearHistory: Bool
    
    public var createdAt: String
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public init(clearHistory: Bool, createdAt: String, type: String, user: StreamChatUserObject?, channel: StreamChatChannelResponse?, channelId: String, channelType: String, cid: String) {
        self.clearHistory = clearHistory
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case clearHistory = "clear_history"
        
        case createdAt = "created_at"
        
        case type
        
        case user
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(clearHistory, forKey: .clearHistory)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
    }
}
