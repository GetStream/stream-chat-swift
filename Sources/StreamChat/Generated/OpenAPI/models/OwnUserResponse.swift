//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class OwnUserResponse: Sendable, Decodable {
    let avgResponseTime: Int?
    let banned: Bool
    let blockedUserIds: [String]?
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
    /// The privacy settings of the user.
    let privacySettings: UserPrivacySettings?
    /// The push preference details.
    let pushPreferences: PushPreference?
    let role: String
    let teams: [String]
    let teamsRole: [String: String]?
    let totalUnreadCount: Int
    let totalUnreadCountByTeam: [String: Int]?
    let unreadChannels: Int
    let unreadThreads: Int
    let updatedAt: Date

    init(
        avgResponseTime: Int? = nil,
        banned: Bool,
        blockedUserIds: [String]? = nil,
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
        pushPreferences: PushPreference? = nil,
        role: String,
        teams: [String],
        teamsRole: [String: String]? = nil,
        totalUnreadCount: Int,
        totalUnreadCountByTeam: [String: Int]? = nil,
        unreadChannels: Int,
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
        self.pushPreferences = pushPreferences
        self.role = role
        self.teams = teams
        self.teamsRole = teamsRole
        self.totalUnreadCount = totalUnreadCount
        self.totalUnreadCountByTeam = totalUnreadCountByTeam
        self.unreadChannels = unreadChannels
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
        case pushPreferences = "push_preferences"
        case role
        case teams
        case teamsRole = "teams_role"
        case totalUnreadCount = "total_unread_count"
        case totalUnreadCountByTeam = "total_unread_count_by_team"
        case unreadChannels = "unread_channels"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        avgResponseTime = try container.decodeIfPresent(Int.self, forKey: .avgResponseTime)
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned) ?? false
        blockedUserIds = try container.decodeIfPresent([String].self, forKey: .blockedUserIds)
        channelMutes = try container.decodeArrayIgnoringFailures(
            [MutedChannelPayload].self,
            forKey: .channelMutes
        )
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        devices = try container.decodeArrayIgnoringFailures([Device].self, forKey: .devices)
        id = try container.decode(String.self, forKey: .id)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible) ?? false
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? ""
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        mutes = try container.decode([MutedUserPayload].self, forKey: .mutes)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        online = try container.decode(Bool.self, forKey: .online)
        privacySettings = try container.decodeIfPresent(
            UserPrivacySettings.self,
            forKey: .privacySettings
        )
        pushPreferences = try container.decodeIfPresent(
            PushPreference.self,
            forKey: .pushPreferences
        )
        role = try container.decode(String.self, forKey: .role)
        teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        teamsRole = try container.decodeIfPresent([String: String].self, forKey: .teamsRole)
        totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
        totalUnreadCountByTeam = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .totalUnreadCountByTeam
        )
        unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
        unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads) ?? 0
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
