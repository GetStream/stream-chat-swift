//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUser: Codable, Hashable {
    public var online: Bool
    
    public var role: String
    
    public var banned: Bool
    
    public var channelMutes: [StreamChatChannelMute?]
    
    public var createdAt: String
    
    public var id: String
    
    public var invisible: Bool?
    
    public var mutes: [StreamChatUserMute?]
    
    public var totalUnreadCount: Int
    
    public var teams: [String]?
    
    public var unreadChannels: Int
    
    public var unreadCount: Int
    
    public var updatedAt: String
    
    public var deletedAt: String?
    
    public var devices: [StreamChatDevice]
    
    public var latestHiddenChannels: [String]?
    
    public var custom: [String: RawJSON]
    
    public var deactivatedAt: String?
    
    public var language: String
    
    public var lastActive: String?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public init(online: Bool, role: String, banned: Bool, channelMutes: [StreamChatChannelMute?], createdAt: String, id: String, invisible: Bool?, mutes: [StreamChatUserMute?], totalUnreadCount: Int, teams: [String]?, unreadChannels: Int, unreadCount: Int, updatedAt: String, deletedAt: String?, devices: [StreamChatDevice], latestHiddenChannels: [String]?, custom: [String: RawJSON], deactivatedAt: String?, language: String, lastActive: String?, pushNotifications: StreamChatPushNotificationSettings?) {
        self.online = online
        
        self.role = role
        
        self.banned = banned
        
        self.channelMutes = channelMutes
        
        self.createdAt = createdAt
        
        self.id = id
        
        self.invisible = invisible
        
        self.mutes = mutes
        
        self.totalUnreadCount = totalUnreadCount
        
        self.teams = teams
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.updatedAt = updatedAt
        
        self.deletedAt = deletedAt
        
        self.devices = devices
        
        self.latestHiddenChannels = latestHiddenChannels
        
        self.custom = custom
        
        self.deactivatedAt = deactivatedAt
        
        self.language = language
        
        self.lastActive = lastActive
        
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case online
        
        case role
        
        case banned
        
        case channelMutes = "channel_mutes"
        
        case createdAt = "created_at"
        
        case id
        
        case invisible
        
        case mutes
        
        case totalUnreadCount = "total_unread_count"
        
        case teams
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case updatedAt = "updated_at"
        
        case deletedAt = "deleted_at"
        
        case devices
        
        case latestHiddenChannels = "latest_hidden_channels"
        
        case custom = "Custom"
        
        case deactivatedAt = "deactivated_at"
        
        case language
        
        case lastActive = "last_active"
        
        case pushNotifications = "push_notifications"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
    }
}
