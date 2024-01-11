//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUser: Codable, Hashable {
    public var unreadChannels: Int
    
    public var channelMutes: [StreamChatChannelMute?]
    
    public var createdAt: String
    
    public var deactivatedAt: String?
    
    public var deletedAt: String?
    
    public var language: String
    
    public var online: Bool
    
    public var role: String
    
    public var updatedAt: String
    
    public var custom: [String: RawJSON]
    
    public var devices: [StreamChatDevice?]
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var id: String
    
    public var latestHiddenChannels: [String]?
    
    public var teams: [String]?
    
    public var banned: Bool
    
    public var invisible: Bool?
    
    public var lastActive: String?
    
    public var mutes: [StreamChatUserMute?]
    
    public var totalUnreadCount: Int
    
    public var unreadCount: Int
    
    public init(unreadChannels: Int, channelMutes: [StreamChatChannelMute?], createdAt: String, deactivatedAt: String?, deletedAt: String?, language: String, online: Bool, role: String, updatedAt: String, custom: [String: RawJSON], devices: [StreamChatDevice?], pushNotifications: StreamChatPushNotificationSettings?, id: String, latestHiddenChannels: [String]?, teams: [String]?, banned: Bool, invisible: Bool?, lastActive: String?, mutes: [StreamChatUserMute?], totalUnreadCount: Int, unreadCount: Int) {
        self.unreadChannels = unreadChannels
        
        self.channelMutes = channelMutes
        
        self.createdAt = createdAt
        
        self.deactivatedAt = deactivatedAt
        
        self.deletedAt = deletedAt
        
        self.language = language
        
        self.online = online
        
        self.role = role
        
        self.updatedAt = updatedAt
        
        self.custom = custom
        
        self.devices = devices
        
        self.pushNotifications = pushNotifications
        
        self.id = id
        
        self.latestHiddenChannels = latestHiddenChannels
        
        self.teams = teams
        
        self.banned = banned
        
        self.invisible = invisible
        
        self.lastActive = lastActive
        
        self.mutes = mutes
        
        self.totalUnreadCount = totalUnreadCount
        
        self.unreadCount = unreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unreadChannels = "unread_channels"
        
        case channelMutes = "channel_mutes"
        
        case createdAt = "created_at"
        
        case deactivatedAt = "deactivated_at"
        
        case deletedAt = "deleted_at"
        
        case language
        
        case online
        
        case role
        
        case updatedAt = "updated_at"
        
        case custom
        
        case devices
        
        case pushNotifications = "push_notifications"
        
        case id
        
        case latestHiddenChannels = "latest_hidden_channels"
        
        case teams
        
        case banned
        
        case invisible
        
        case lastActive = "last_active"
        
        case mutes
        
        case totalUnreadCount = "total_unread_count"
        
        case unreadCount = "unread_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}
