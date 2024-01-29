//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable, Event {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: Date
    
    public var totalUnreadCount: Int
    
    public var type: String
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var team: String? = nil
    
    public var channel: StreamChatChannelResponse? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(channelId: String, channelType: String, cid: String, createdAt: Date, totalUnreadCount: Int, type: String, unreadChannels: Int, unreadCount: Int, team: String? = nil, channel: StreamChatChannelResponse? = nil, user: StreamChatUserObject? = nil) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.totalUnreadCount = totalUnreadCount
        
        self.type = type
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.team = team
        
        self.channel = channel
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case totalUnreadCount = "total_unread_count"
        
        case type
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case team
        
        case channel
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(user, forKey: .user)
    }
}

extension StreamChatNotificationMarkReadEvent: EventContainsUnreadCount {}

extension StreamChatNotificationMarkReadEvent: EventContainsChannel {}

extension StreamChatNotificationMarkReadEvent: EventContainsUser {}
