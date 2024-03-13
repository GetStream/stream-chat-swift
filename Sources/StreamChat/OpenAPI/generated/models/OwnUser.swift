//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct OwnUser: Codable, Hashable {
    public var banned: Bool
    public var createdAt: Date
    public var id: String
    public var language: String
    public var online: Bool
    public var role: String
    public var totalUnreadCount: Int
    public var unreadChannels: Int
    public var unreadCount: Int
    public var unreadThreads: Int
    public var updatedAt: Date
    public var channelMutes: [ChannelMute?]
    public var devices: [Device]
    public var mutes: [UserMute?]
    public var custom: [String: RawJSON]?
    public var deactivatedAt: Date? = nil
    public var deletedAt: Date? = nil
    public var invisible: Bool? = nil
    public var lastActive: Date? = nil
    public var latestHiddenChannels: [String]? = nil
    public var teams: [String]? = nil
    public var pushNotifications: PushNotificationSettings? = nil

    public init(banned: Bool, createdAt: Date, id: String, language: String, online: Bool, role: String, totalUnreadCount: Int, unreadChannels: Int, unreadCount: Int, unreadThreads: Int, updatedAt: Date, channelMutes: [ChannelMute?], devices: [Device], mutes: [UserMute?], custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, invisible: Bool? = nil, lastActive: Date? = nil, latestHiddenChannels: [String]? = nil, teams: [String]? = nil, pushNotifications: PushNotificationSettings? = nil) {
        self.banned = banned
        self.createdAt = createdAt
        self.id = id
        self.language = language
        self.online = online
        self.role = role
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
        self.unreadThreads = unreadThreads
        self.updatedAt = updatedAt
        self.channelMutes = channelMutes
        self.devices = devices
        self.mutes = mutes
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.invisible = invisible
        self.lastActive = lastActive
        self.latestHiddenChannels = latestHiddenChannels
        self.teams = teams
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case createdAt = "created_at"
        case id
        case language
        case online
        case role
        case totalUnreadCount = "total_unread_count"
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
        case channelMutes = "channel_mutes"
        case devices
        case mutes
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case invisible
        case lastActive = "last_active"
        case latestHiddenChannels = "latest_hidden_channels"
        case teams
        case pushNotifications = "push_notifications"
    }
}
