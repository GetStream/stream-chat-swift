//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable, Event {
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var cid: String
    
    public var unreadChannels: Int
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var createdAt: Date
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var type: String
    
    public var unreadCount: Int
    
    public init(channel: StreamChatChannelResponse?, channelId: String, cid: String, unreadChannels: Int, user: StreamChatUserObject?, channelType: String, createdAt: Date, team: String?, totalUnreadCount: Int, type: String, unreadCount: Int) {
        self.channel = channel
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.unreadChannels = unreadChannels
        
        self.user = user
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.type = type
        
        self.unreadCount = unreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case channelId = "channel_id"
        
        case cid
        
        case unreadChannels = "unread_channels"
        
        case user
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case type
        
        case unreadCount = "unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}
