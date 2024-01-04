//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUserRequest: Codable, Hashable {
    public var language: String?
    
    public var online: Bool?
    
    public var pushNotifications: StreamChatPushNotificationSettingsRequest1?
    
    public var unreadChannels: Int?
    
    public var unreadCount: Int?
    
    public var channelMutes: [StreamChatChannelMuteRequest?]?
    
    public var deletedAt: String?
    
    public var totalUnreadCount: Int?
    
    public var deactivatedAt: String?
    
    public var lastActive: String?
    
    public var custom: [String: RawJSON]?
    
    public var banned: Bool?
    
    public var id: String?
    
    public var invisible: Bool?
    
    public var latestHiddenChannels: [String]?
    
    public var mutes: [StreamChatUserMuteRequest?]?
    
    public var role: String?
    
    public var teams: [String]?
    
    public var createdAt: String?
    
    public var devices: [StreamChatDeviceRequest?]?
    
    public var updatedAt: String?
    
    public init(language: String?, online: Bool?, pushNotifications: StreamChatPushNotificationSettingsRequest1?, unreadChannels: Int?, unreadCount: Int?, channelMutes: [StreamChatChannelMuteRequest?]?, deletedAt: String?, totalUnreadCount: Int?, deactivatedAt: String?, lastActive: String?, custom: [String: RawJSON]?, banned: Bool?, id: String?, invisible: Bool?, latestHiddenChannels: [String]?, mutes: [StreamChatUserMuteRequest?]?, role: String?, teams: [String]?, createdAt: String?, devices: [StreamChatDeviceRequest?]?, updatedAt: String?) {
        self.language = language
        
        self.online = online
        
        self.pushNotifications = pushNotifications
        
        self.unreadChannels = unreadChannels
        
        self.unreadCount = unreadCount
        
        self.channelMutes = channelMutes
        
        self.deletedAt = deletedAt
        
        self.totalUnreadCount = totalUnreadCount
        
        self.deactivatedAt = deactivatedAt
        
        self.lastActive = lastActive
        
        self.custom = custom
        
        self.banned = banned
        
        self.id = id
        
        self.invisible = invisible
        
        self.latestHiddenChannels = latestHiddenChannels
        
        self.mutes = mutes
        
        self.role = role
        
        self.teams = teams
        
        self.createdAt = createdAt
        
        self.devices = devices
        
        self.updatedAt = updatedAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case language
        
        case online
        
        case pushNotifications = "push_notifications"
        
        case unreadChannels = "unread_channels"
        
        case unreadCount = "unread_count"
        
        case channelMutes = "channel_mutes"
        
        case deletedAt = "deleted_at"
        
        case totalUnreadCount = "total_unread_count"
        
        case deactivatedAt = "deactivated_at"
        
        case lastActive = "last_active"
        
        case custom = "Custom"
        
        case banned
        
        case id
        
        case invisible
        
        case latestHiddenChannels = "latest_hidden_channels"
        
        case mutes
        
        case role
        
        case teams
        
        case createdAt = "created_at"
        
        case devices
        
        case updatedAt = "updated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(unreadChannels, forKey: .unreadChannels)
        
        try container.encode(unreadCount, forKey: .unreadCount)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(latestHiddenChannels, forKey: .latestHiddenChannels)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
