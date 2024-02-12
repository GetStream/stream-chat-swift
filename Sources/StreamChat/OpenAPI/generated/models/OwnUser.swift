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

    public init(banned: Bool, createdAt: Date, id: String, language: String, online: Bool, role: String, totalUnreadCount: Int, unreadChannels: Int, unreadCount: Int, updatedAt: Date, channelMutes: [ChannelMute?], devices: [Device], mutes: [UserMute?], custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, invisible: Bool? = nil, lastActive: Date? = nil, latestHiddenChannels: [String]? = nil, teams: [String]? = nil, pushNotifications: PushNotificationSettings? = nil) {
        self.banned = banned
        self.createdAt = createdAt
        self.id = id
        self.language = language
        self.online = online
        self.role = role
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadCount = unreadCount
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(banned, forKey: .banned)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(id, forKey: .id)
        try container.encode(language, forKey: .language)
        try container.encode(online, forKey: .online)
        try container.encode(role, forKey: .role)
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        try container.encode(unreadChannels, forKey: .unreadChannels)
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(channelMutes, forKey: .channelMutes)
        try container.encode(devices, forKey: .devices)
        try container.encode(mutes, forKey: .mutes)
        try container.encode(custom, forKey: .custom)
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        try container.encode(deletedAt, forKey: .deletedAt)
        try container.encode(invisible, forKey: .invisible)
        try container.encode(lastActive, forKey: .lastActive)
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        try container.encode(teams, forKey: .teams)
        try container.encode(pushNotifications, forKey: .pushNotifications)
    }
}
