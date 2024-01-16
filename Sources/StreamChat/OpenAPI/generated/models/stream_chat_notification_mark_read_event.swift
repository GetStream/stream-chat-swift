//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var channelId: String
    
    public var channelType: String
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var createdAt: String
    
    public init(cid: String, team: String?, totalUnreadCount: Int, unreadChannels: Int, unreadCount: Int, channelId: String, channelType: String, type: String, user: StreamChatUserObject?, channel: StreamChatChannelResponse?, createdAt: String) {
        self.cid = cid
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.type = type
        
        self.user = user
        
        self.channel = channel
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case type
        
        case user
        
        case channel
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}
