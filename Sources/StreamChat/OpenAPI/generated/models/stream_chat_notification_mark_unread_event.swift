//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkUnreadEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var createdAt: Date
    
    public var totalUnreadCount: Int
    
    public var lastReadAt: Date
    
    public var unreadMessages: Int
    
    public var channelId: String
    
    public var firstUnreadMessageId: String
    
    public var lastReadMessageId: String?
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public var channelType: String
    
    public var team: String?
    
    public var type: String
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public init(cid: String, createdAt: Date, totalUnreadCount: Int, lastReadAt: Date, unreadMessages: Int, channelId: String, firstUnreadMessageId: String, lastReadMessageId: String?, user: StreamChatUserObject?, channel: StreamChatChannelResponse?, channelType: String, team: String?, type: String, unreadChannels: Int, unreadCount: Int) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.totalUnreadCount = totalUnreadCount
        
        self.lastReadAt = lastReadAt
        
        self.unreadMessages = unreadMessages
        
        self.channelId = channelId
        
        self.firstUnreadMessageId = firstUnreadMessageId
        
        self.lastReadMessageId = lastReadMessageId
        
        self.user = user
        
        self.channel = channel
        
        self.channelType = channelType
        
        self.team = team
        
        self.type = type
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case totalUnreadCount = "total_unread_count"
        
        case lastReadAt = "last_read_at"
        
        case unreadMessages = "unread_messages"
        
        case channelId = "channel_id"
        
        case firstUnreadMessageId = "first_unread_message_id"
        
        case lastReadMessageId = "last_read_message_id"
        
        case user
        
        case channel
        
        case channelType = "channel_type"
        
        case team
        
        case type
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(lastReadAt, forKey: .lastReadAt)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(firstUnreadMessageId, forKey: .firstUnreadMessageId)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}
