//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkUnreadEvent: Codable, Hashable {
    public var firstUnreadMessageId: String
    
    public var lastReadAt: String
    
    public var type: String
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var unreadMessages: Int
    
    public var createdAt: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var channel: StreamChatChannelResponse?
    
    public var cid: String
    
    public var lastReadMessageId: String?
    
    public init(firstUnreadMessageId: String, lastReadAt: String, type: String, unreadChannels: Int, unreadCount: Int, unreadMessages: Int, createdAt: String, user: StreamChatUserObject?, channelId: String, channelType: String, team: String?, totalUnreadCount: Int, channel: StreamChatChannelResponse?, cid: String, lastReadMessageId: String?) {
        self.firstUnreadMessageId = firstUnreadMessageId
        
        self.lastReadAt = lastReadAt
        
        self.type = type
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.unreadMessages = unreadMessages
        
        self.createdAt = createdAt
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.channel = channel
        
        self.cid = cid
        
        self.lastReadMessageId = lastReadMessageId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case firstUnreadMessageId = "first_unread_message_id"
        
        case lastReadAt = "last_read_at"
        
        case type
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case unreadMessages = "unread_messages"
        
        case createdAt = "created_at"
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case channel
        
        case cid
        
        case lastReadMessageId = "last_read_message_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(firstUnreadMessageId, forKey: .firstUnreadMessageId)
        
        try container.encode(lastReadAt, forKey: .lastReadAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
    }
}
