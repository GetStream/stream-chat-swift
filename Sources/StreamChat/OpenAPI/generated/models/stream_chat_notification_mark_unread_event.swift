//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkUnreadEvent: Codable, Hashable {
    public var unreadMessages: Int
    
    public var channel: StreamChatChannelResponse?
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var firstUnreadMessageId: String
    
    public var lastReadAt: String
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var lastReadMessageId: String?
    
    public init(unreadMessages: Int, channel: StreamChatChannelResponse?, unreadChannels: Int, unreadCount: Int, type: String, user: StreamChatUserObject?, createdAt: String, firstUnreadMessageId: String, lastReadAt: String, team: String?, totalUnreadCount: Int, channelId: String, channelType: String, cid: String, lastReadMessageId: String?) {
        self.unreadMessages = unreadMessages
        
        self.channel = channel
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.type = type
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.firstUnreadMessageId = firstUnreadMessageId
        
        self.lastReadAt = lastReadAt
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.lastReadMessageId = lastReadMessageId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unreadMessages = "unread_messages"
        
        case channel
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case type
        
        case user
        
        case createdAt = "created_at"
        
        case firstUnreadMessageId = "first_unread_message_id"
        
        case lastReadAt = "last_read_at"
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case lastReadMessageId = "last_read_message_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(firstUnreadMessageId, forKey: .firstUnreadMessageId)
        
        try container.encode(lastReadAt, forKey: .lastReadAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
    }
}
