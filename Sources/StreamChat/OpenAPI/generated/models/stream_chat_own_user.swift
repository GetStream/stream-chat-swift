//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUser: Codable, Hashable {
    public var channelMutes: [StreamChatChannelMute?]
    
    public var id: String
    
    public var unreadChannels: Int
    
    public var teams: [String]?
    
    public var totalUnreadCount: Int
    
    public var custom: [String: RawJSON]
    
    public var createdAt: Date
    
    public var deletedAt: Date?
    
    public var language: String
    
    public var latestHiddenChannels: [String]?
    
    public var online: Bool
    
    public var updatedAt: Date
    
    public var banned: Bool
    
    public var deactivatedAt: Date?
    
    public var lastActive: Date?
    
    public var mutes: [StreamChatUserMute?]
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var devices: [StreamChatDevice]
    
    public var invisible: Bool?
    
    public var role: String
    
    public var unreadCount: Int
    
    public init(channelMutes: [StreamChatChannelMute?], id: String, unreadChannels: Int, teams: [String]?, totalUnreadCount: Int, custom: [String: RawJSON], createdAt: Date, deletedAt: Date?, language: String, latestHiddenChannels: [String]?, online: Bool, updatedAt: Date, banned: Bool, deactivatedAt: Date?, lastActive: Date?, mutes: [StreamChatUserMute?], pushNotifications: StreamChatPushNotificationSettings?, devices: [StreamChatDevice], invisible: Bool?, role: String, unreadCount: Int) {
        self.channelMutes = channelMutes
        
        self.id = id
        
        self.unreadChannels = unreadChannels
        
        self.teams = teams
        
        self.totalUnreadCount = totalUnreadCount
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.language = language
        
        self.latestHiddenChannels = latestHiddenChannels
        
        self.online = online
        
        self.updatedAt = updatedAt
        
        self.banned = banned
        
        self.deactivatedAt = deactivatedAt
        
        self.lastActive = lastActive
        
        self.mutes = mutes
        
        self.pushNotifications = pushNotifications
        
        self.devices = devices
        
        self.invisible = invisible
        
        self.role = role
        
        self.unreadCount = unreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMutes = "channel_mutes"
        
        case id
        
        case unreadChannels = "unread_channels"
        
        case teams
        
        case totalUnreadCount = "total_unread_count"
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case language
        
        case latestHiddenChannels = "latest_hidden_channels"
        
        case online
        
        case updatedAt = "updated_at"
        
        case banned
        
        case deactivatedAt = "deactivated_at"
        
        case lastActive = "last_active"
        
        case mutes
        
        case pushNotifications = "push_notifications"
        
        case devices
        
        case invisible
        
        case role
        
        case unreadCount = "unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}
