//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkReadEvent: Codable, Hashable {
    public var cid: String
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var channelType: String
    
    public var createdAt: String
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public init(cid: String, team: String?, totalUnreadCount: Int, unreadChannels: Int, unreadCount: Int, channel: StreamChatChannelResponse?, channelId: String, channelType: String, createdAt: String, type: String, user: StreamChatUserObject?) {
        self.cid = cid
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.createdAt = createdAt
        
        self.type = type
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case channel
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case createdAt = "created_at"
        
        case type
        
        case user
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
    }
}
