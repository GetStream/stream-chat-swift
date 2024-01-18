//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUser: Codable, Hashable {
    public var language: String
    
    public var latestHiddenChannels: [String]?
    
    public var online: Bool
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var custom: [String: RawJSON]
    
    public var banned: Bool
    
    public var devices: [StreamChatDevice?]
    
    public var updatedAt: Date
    
    public var invisible: Bool?
    
    public var totalUnreadCount: Int
    
    public var teams: [String]?
    
    public var createdAt: Date
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var role: String
    
    public var id: String
    
    public var lastActive: Date?
    
    public var mutes: [StreamChatUserMute?]
    
    public var channelMutes: [StreamChatChannelMute?]
    
    public var deactivatedAt: Date?
    
    public var deletedAt: Date?
    
    public init(language: String, latestHiddenChannels: [String]?, online: Bool, unreadChannels: Int, unreadCount: Int, custom: [String: RawJSON], banned: Bool, devices: [StreamChatDevice?], updatedAt: Date, invisible: Bool?, totalUnreadCount: Int, teams: [String]?, createdAt: Date, pushNotifications: StreamChatPushNotificationSettings?, role: String, id: String, lastActive: Date?, mutes: [StreamChatUserMute?], channelMutes: [StreamChatChannelMute?], deactivatedAt: Date?, deletedAt: Date?) {
        self.language = language
        
        self.latestHiddenChannels = latestHiddenChannels
        
        self.online = online
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.custom = custom
        
        self.banned = banned
        
        self.devices = devices
        
        self.updatedAt = updatedAt
        
        self.invisible = invisible
        
        self.totalUnreadCount = totalUnreadCount
        
        self.teams = teams
        
        self.createdAt = createdAt
        
        self.pushNotifications = pushNotifications
        
        self.role = role
        
        self.id = id
        
        self.lastActive = lastActive
        
        self.mutes = mutes
        
        self.channelMutes = channelMutes
        
        self.deactivatedAt = deactivatedAt
        
        self.deletedAt = deletedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case language
        
        case latestHiddenChannels = "latest_hidden_channels"
        
        case online
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case custom = "Custom"
        
        case banned
        
        case devices
        
        case updatedAt = "updated_at"
        
        case invisible
        
        case totalUnreadCount = "total_unread_count"
        
        case teams
        
        case createdAt = "created_at"
        
        case pushNotifications = "push_notifications"
        
        case role
        
        case id
        
        case lastActive = "last_active"
        
        case mutes
        
        case channelMutes = "channel_mutes"
        
        case deactivatedAt = "deactivated_at"
        
        case deletedAt = "deleted_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
    }
}
