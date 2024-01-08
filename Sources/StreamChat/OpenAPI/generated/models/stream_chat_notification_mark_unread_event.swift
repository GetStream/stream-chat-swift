//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationMarkUnreadEvent: Codable, Hashable {
    public var firstUnreadMessageId: String
    
    public var team: String?
    
    public var totalUnreadCount: Int
    
    public var user: StreamChatUserObject?
    
    public var channelType: String
    
    public var cid: String
    
    public var lastReadMessageId: String?
    
    public var type: String
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var unreadMessages: Int
    
    public var channel: StreamChatChannelResponse?
    
    public var channelId: String
    
    public var createdAt: String
    
    public var lastReadAt: String
    
    public init(firstUnreadMessageId: String, team: String?, totalUnreadCount: Int, user: StreamChatUserObject?, channelType: String, cid: String, lastReadMessageId: String?, type: String, unreadChannels: Int, unreadCount: Int, unreadMessages: Int, channel: StreamChatChannelResponse?, channelId: String, createdAt: String, lastReadAt: String) {
        self.firstUnreadMessageId = firstUnreadMessageId
        
        self.team = team
        
        self.totalUnreadCount = totalUnreadCount
        
        self.user = user
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.lastReadMessageId = lastReadMessageId
        
        self.type = type
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.unreadMessages = unreadMessages
        
        self.channel = channel
        
        self.channelId = channelId
        
        self.createdAt = createdAt
        
        self.lastReadAt = lastReadAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case firstUnreadMessageId = "first_unread_message_id"
        
        case team
        
        case totalUnreadCount = "total_unread_count"
        
        case user
        
        case channelType = "channel_type"
        
        case cid
        
        case lastReadMessageId = "last_read_message_id"
        
        case type
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case unreadMessages = "unread_messages"
        
        case channel
        
        case channelId = "channel_id"
        
        case createdAt = "created_at"
        
        case lastReadAt = "last_read_at"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(firstUnreadMessageId, forKey: .firstUnreadMessageId)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(unreadMessages, forKey: .unreadMessages)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(lastReadAt, forKey: .lastReadAt)
    }
}
