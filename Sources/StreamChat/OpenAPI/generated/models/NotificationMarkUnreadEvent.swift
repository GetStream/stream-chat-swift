//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationMarkUnreadEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var firstUnreadMessageId: String
    public var lastReadAt: Date
    public var totalUnreadCount: Int
    public var type: String
    public var unreadChannels: Int
    public var unreadCount: Int
    public var unreadMessages: Int
    public var unreadThreads: Int
    public var lastReadMessageId: String? = nil
    public var team: String? = nil
    public var channel: ChannelResponse? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, firstUnreadMessageId: String, lastReadAt: Date, totalUnreadCount: Int, type: String, unreadChannels: Int, unreadCount: Int, unreadMessages: Int, unreadThreads: Int, lastReadMessageId: String? = nil, team: String? = nil, channel: ChannelResponse? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.firstUnreadMessageId = firstUnreadMessageId
        self.lastReadAt = lastReadAt
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.unreadMessages = unreadMessages
        self.unreadThreads = unreadThreads
        self.lastReadMessageId = lastReadMessageId
        self.team = team
        self.channel = channel
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case firstUnreadMessageId = "first_unread_message_id"
        case lastReadAt = "last_read_at"
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case unreadMessages = "unread_messages"
        case unreadThreads = "unread_threads"
        case lastReadMessageId = "last_read_message_id"
        case team
        case channel
        case user
    }
}

extension NotificationMarkUnreadEvent: EventContainsCid {}
extension NotificationMarkUnreadEvent: EventContainsCreationDate {}
extension NotificationMarkUnreadEvent: EventContainsUnreadCount {}
extension NotificationMarkUnreadEvent: EventContainsChannel {}
extension NotificationMarkUnreadEvent: EventContainsUser {}