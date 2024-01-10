//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var team: String?
    
    public var type: String
    
    public var unreadChannels: Int
    
    public var cid: String
    
    public var createdAt: String
    
    public var totalUnreadCount: Int
    
    public var unreadCount: Int
    
    public var user: StreamChatUserObject?
    
    public init(channel: StreamChatChannelResponse?, channelId: String, channelType: String, team: String?, type: String, unreadChannels: Int, cid: String, createdAt: String, totalUnreadCount: Int, unreadCount: Int, user: StreamChatUserObject?) {
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.team = team
        
        self.type = type
        
        self.unreadChannels = unreadChannels
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.totalUnreadCount = totalUnreadCount
        
        self.unreadCount = unreadCount
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case team
        
        case type
        
        case unreadChannels = "unread_channels"
        
        case cid
        
        case createdAt = "created_at"
        
        case totalUnreadCount = "total_unread_count"
        
        case unreadCount = "unread_count"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(user, forKey: .user)
    }
}
