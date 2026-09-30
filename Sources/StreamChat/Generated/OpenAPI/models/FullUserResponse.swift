//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FullUserResponse: Sendable, Decodable {
    let avgResponseTime: Int?
    let banned: Bool
    let blockedUserIds: [String]
    let channelMutes: [MutedChannelPayload]
    let createdAt: Date
    let custom: [String: RawJSON]
    let deactivatedAt: Date?
    let devices: [Device]
    let id: String
    let image: String?
    let invisible: Bool
    let language: String
    let lastActive: Date?
    let mutes: [MutedUserPayload]
    let name: String?
    let online: Bool
    let privacySettings: UserPrivacySettings?
    let role: String
    let teams: [String]
    let teamsRole: [String: String]?
    let totalUnreadCount: Int
    let unreadChannels: Int
    /// Deprecated: Use total_unread_count instead.
    @available(
        *,
        deprecated,
        message: "Use total_unread_count instead.",
        renamed: "totalUnreadCount"
    )
    var unreadCount: Int { _unreadCount }
    private let _unreadCount: Int
    let unreadThreads: Int
    let updatedAt: Date

    init(
        avgResponseTime: Int? = nil,
        banned: Bool,
        blockedUserIds: [String],
        channelMutes: [MutedChannelPayload],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        devices: [Device],
        id: String,
        image: String? = nil,
        invisible: Bool,
        language: String,
        lastActive: Date? = nil,
        mutes: [MutedUserPayload],
        name: String? = nil,
        online: Bool,
        privacySettings: UserPrivacySettings? = nil,
        role: String,
        teams: [String],
        teamsRole: [String: String]? = nil,
        totalUnreadCount: Int,
        unreadChannels: Int,
        unreadCount: Int,
        unreadThreads: Int,
        updatedAt: Date
    ) {
        self.avgResponseTime = avgResponseTime
        self.banned = banned
        self.blockedUserIds = blockedUserIds
        self.channelMutes = channelMutes
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.devices = devices
        self.id = id
        self.image = image
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.mutes = mutes
        self.name = name
        self.online = online
        self.privacySettings = privacySettings
        self.role = role
        self.teams = teams
        self.teamsRole = teamsRole
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self._unreadCount = unreadCount
        self.unreadThreads = unreadThreads
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case avgResponseTime = "avg_response_time"
        case banned
        case blockedUserIds = "blocked_user_ids"
        case channelMutes = "channel_mutes"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case devices
        case id
        case image
        case invisible
        case language
        case lastActive = "last_active"
        case mutes
        case name
        case online
        case privacySettings = "privacy_settings"
        case role
        case teams
        case teamsRole = "teams_role"
        case totalUnreadCount = "total_unread_count"
        case unreadChannels = "unread_channels"
        case unreadCount = "unread_count"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.avgResponseTime = try container.decodeIfPresent(Int.self, forKey: .avgResponseTime)
        self.banned = try container.decode(Bool.self, forKey: .banned)
        self.blockedUserIds = try container.decode([String].self, forKey: .blockedUserIds)
        self.channelMutes = try container.decode([MutedChannelPayload].self, forKey: .channelMutes)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        self.devices = try container.decode([Device].self, forKey: .devices)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.invisible = try container.decode(Bool.self, forKey: .invisible)
        self.language = try container.decode(String.self, forKey: .language)
        self.lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        self.mutes = try container.decode([MutedUserPayload].self, forKey: .mutes)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.online = try container.decode(Bool.self, forKey: .online)
        self.privacySettings = try container.decodeIfPresent(
            UserPrivacySettings.self,
            forKey: .privacySettings
        )
        self.role = try container.decode(String.self, forKey: .role)
        self.teams = try container.decode([String].self, forKey: .teams)
        self.teamsRole = try container.decodeIfPresent([String: String].self, forKey: .teamsRole)
        self.totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
        self.unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
        self._unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        self.unreadThreads = try container.decode(Int.self, forKey: .unreadThreads)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(avgResponseTime, forKey: .avgResponseTime)
        try container.encode(banned, forKey: .banned)
        try container.encode(blockedUserIds, forKey: .blockedUserIds)
        try container.encode(channelMutes, forKey: .channelMutes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(deactivatedAt, forKey: .deactivatedAt)
        try container.encode(devices, forKey: .devices)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(invisible, forKey: .invisible)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(lastActive, forKey: .lastActive)
        try container.encode(mutes, forKey: .mutes)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(online, forKey: .online)
        try container.encodeIfPresent(privacySettings, forKey: .privacySettings)
        try container.encode(role, forKey: .role)
        try container.encode(teams, forKey: .teams)
        try container.encodeIfPresent(teamsRole, forKey: .teamsRole)
        try container.encode(totalUnreadCount, forKey: .totalUnreadCount)
        try container.encode(unreadChannels, forKey: .unreadChannels)
        try container.encode(_unreadCount, forKey: .unreadCount)
        try container.encode(unreadThreads, forKey: .unreadThreads)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
