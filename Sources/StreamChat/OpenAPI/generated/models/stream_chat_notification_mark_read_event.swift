//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var team: String?
    
    public var user: StreamChatUserObject?
    
    public var unreadCount: Int
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: Date
    
    public var totalUnreadCount: Int
    
    public var type: String
    
    public var unreadChannels: Int
    
    public init(cid: String, team: String?, user: StreamChatUserObject?, unreadCount: Int, channel: StreamChatChannelResponse?, channelId: String, channelType: String, createdAt: Date, totalUnreadCount: Int, type: String, unreadChannels: Int) {
        self.cid = cid
        
        self.team = team
        
        self.user = user
        
        self.unreadCount = unreadCount
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.totalUnreadCount = totalUnreadCount
        
        self.type = type
        
        self.unreadChannels = unreadChannels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case team
        
        case user
        
        case unreadCount = "unread_count"
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case totalUnreadCount = "total_unread_count"
        
        case type
        
        case unreadChannels = "unread_channels"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
    }
}
