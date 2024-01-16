//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkUnreadEvent: Codable, Hashable, Event {
    public var totalUnreadCount: Int
    
    public var type: String
    
    public var unreadMessages: Int
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var firstUnreadMessageId: String
    
    public var unreadCount: Int
    
    public var lastReadMessageId: String?
    
    public var team: String?
    
    public var unreadChannels: Int
    
    public var lastReadAt: String
    
    public var user: StreamChatUserObject?
    
    public init(totalUnreadCount: Int, type: String, unreadMessages: Int, channelType: String, cid: String, createdAt: String, channel: StreamChatChannelResponse?, channelId: String, firstUnreadMessageId: String, unreadCount: Int, lastReadMessageId: String?, team: String?, unreadChannels: Int, lastReadAt: String, user: StreamChatUserObject?) {
        self.totalUnreadCount = totalUnreadCount
        
        self.type = type
        
        self.unreadMessages = unreadMessages
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.firstUnreadMessageId = firstUnreadMessageId
        
        self.unreadCount = unreadCount
        
        self.lastReadMessageId = lastReadMessageId
        
        self.team = team
        
        self.unreadChannels = unreadChannels
        
        self.lastReadAt = lastReadAt
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case totalUnreadCount = "total_unread_count"
        
        case type
        
        case unreadMessages = "unread_messages"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case channel
        
        case channelId = "channel_id"
        
        case firstUnreadMessageId = "first_unread_message_id"
        
        case unreadCount = "unread_count"
        
        case lastReadMessageId = "last_read_message_id"
        
        case team
        
        case unreadChannels = "unread_channels"
        
        case lastReadAt = "last_read_at"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(firstUnreadMessageId, forKey: .firstUnreadMessageId)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(lastReadAt, forKey: .lastReadAt)
        
        try container.encode(user, forKey: .user)
    }
}
