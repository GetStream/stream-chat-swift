//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkUnreadEvent: Codable, Hashable, Event {
    public var channel: StreamChatChannelResponse?
    
    public var createdAt: Date
    
    public var unreadChannels: Int
    
    public var unreadMessages: Int
    
    public var channelId: String
    
    public var cid: String
    
    public var totalUnreadCount: Int
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var firstUnreadMessageId: String
    
    public var lastReadMessageId: String?
    
    public var unreadCount: Int
    
    public var lastReadAt: Date
    
    public var team: String?
    
    public var type: String
    
    public init(channel: StreamChatChannelResponse?, createdAt: Date, unreadChannels: Int, unreadMessages: Int, channelId: String, cid: String, totalUnreadCount: Int, user: StreamChatUserObject?, channelType: String, firstUnreadMessageId: String, lastReadMessageId: String?, unreadCount: Int, lastReadAt: Date, team: String?, type: String) {
        self.channel = channel
        
        self.createdAt = createdAt
        
        self.unreadChannels = unreadChannels
        
        self.unreadMessages = unreadMessages
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.totalUnreadCount = totalUnreadCount
        
        self.user = user
        
        self.channelType = channelType
        
        self.firstUnreadMessageId = firstUnreadMessageId
        
        self.lastReadMessageId = lastReadMessageId
        
        self.unreadCount = unreadCount
        
        self.lastReadAt = lastReadAt
        
        self.team = team
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case createdAt = "created_at"
        
        case unreadChannels = "unread_channels"
        
        case unreadMessages = "unread_messages"
        
        case channelId = "channel_id"
        
        case cid
        
        case totalUnreadCount = "total_unread_count"
        
        case user
        
        case channelType = "channel_type"
        
        case firstUnreadMessageId = "first_unread_message_id"
        
        case lastReadMessageId = "last_read_message_id"
        
        case unreadCount = "unread_count"
        
        case lastReadAt = "last_read_at"
        
        case team
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(firstUnreadMessageId, forKey: .firstUnreadMessageId)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(lastReadAt, forKey: .lastReadAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
    }
}
