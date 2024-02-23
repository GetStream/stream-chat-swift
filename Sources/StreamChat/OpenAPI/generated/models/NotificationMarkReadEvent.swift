//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationMarkReadEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var totalUnreadCount: Int
    public var type: String
    public var unreadChannels: Int
    public var unreadCount: Int
    public var team: String? = nil
    public var channel: ChannelResponse? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, totalUnreadCount: Int, type: String, unreadChannels: Int, unreadCount: Int, team: String? = nil, channel: ChannelResponse? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.team = team
        self.channel = channel
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case team
        case channel
        case user
    }
}

extension NotificationMarkReadEvent: EventContainsCid {}
extension NotificationMarkReadEvent: EventContainsCreationDate {}
extension NotificationMarkReadEvent: EventContainsUnreadCount {}
extension NotificationMarkReadEvent: EventContainsChannel {}
extension NotificationMarkReadEvent: EventContainsUser {}
