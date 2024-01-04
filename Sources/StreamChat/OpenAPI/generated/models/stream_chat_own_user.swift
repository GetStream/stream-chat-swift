//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUser: Codable, Hashable {
    public var invisible: Bool?
    
    public var totalUnreadCount: Int
    
    public var createdAt: String
    
    public var deactivatedAt: String?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var role: String
    
    public var updatedAt: String
    
    public var deletedAt: String?
    
    public var language: String
    
    public var id: String
    
    public var latestHiddenChannels: [String]?
    
    public var mutes: [StreamChatUserMute?]
    
    public var custom: [String: RawJSON]
    
    public var banned: Bool
    
    public var lastActive: String?
    
    public var online: Bool
    
    public var teams: [String]?
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var channelMutes: [StreamChatChannelMute?]
    
    public var devices: [StreamChatDevice]
    
    public init(invisible: Bool?, totalUnreadCount: Int, createdAt: String, deactivatedAt: String?, pushNotifications: StreamChatPushNotificationSettings?, role: String, updatedAt: String, deletedAt: String?, language: String, id: String, latestHiddenChannels: [String]?, mutes: [StreamChatUserMute?], custom: [String: RawJSON], banned: Bool, lastActive: String?, online: Bool, teams: [String]?, unreadChannels: Int, unreadCount: Int, channelMutes: [StreamChatChannelMute?], devices: [StreamChatDevice]) {
        self.invisible = invisible
        
        self.totalUnreadCount = totalUnreadCount
        
        self.createdAt = createdAt
        
        self.deactivatedAt = deactivatedAt
        
        self.pushNotifications = pushNotifications
        
        self.role = role
        
        self.updatedAt = updatedAt
        
        self.deletedAt = deletedAt
        
        self.language = language
        
        self.id = id
        
        self.latestHiddenChannels = latestHiddenChannels
        
        self.mutes = mutes
        
        self.custom = custom
        
        self.banned = banned
        
        self.lastActive = lastActive
        
        self.online = online
        
        self.teams = teams
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.channelMutes = channelMutes
        
        self.devices = devices
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case invisible
        
        case totalUnreadCount = "total_unread_count"
        
        case createdAt = "created_at"
        
        case deactivatedAt = "deactivated_at"
        
        case pushNotifications = "push_notifications"
        
        case role
        
        case updatedAt = "updated_at"
        
        case deletedAt = "deleted_at"
        
        case language
        
        case id
        
        case latestHiddenChannels = "latest_hidden_channels"
        
        case mutes
        
        case custom = "Custom"
        
        case banned
        
        case lastActive = "last_active"
        
        case online
        
        case teams
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case channelMutes = "channel_mutes"
        
        case devices
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(devices, forKey: .devices)
    }
}
