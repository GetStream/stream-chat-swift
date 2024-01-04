//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable {
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: String
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var type: String
    
    public var unreadCount: Int
    
    public var channel: StreamChatChannelResponse?
    
    public var user: StreamChatUserObject?
    
    public var unreadChannels: Int
    
    public var cid: String
    
    public init(channelId: String, channelType: String, createdAt: String, team: String?, totalUnreadCount: Int, type: String, unreadCount: Int, channel: StreamChatChannelResponse?, user: StreamChatUserObject?, unreadChannels: Int, cid: String) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.type = type
        
        self.unreadCount = unreadCount
        
        self.channel = channel
        
        self.user = user
        
        self.unreadChannels = unreadChannels
        
        self.cid = cid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case type
        
        case unreadCount = "unread_count"
        
        case channel
        
        case user
        
        case unreadChannels = "unread_channels"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(cid, forKey: .cid)
    }
}
