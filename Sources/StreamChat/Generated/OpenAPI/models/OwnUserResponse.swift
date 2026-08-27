//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class OwnUserResponse: Sendable, Decodable {
    let avgResponseTime: Int?
    let banned: Bool?
    let blockedUserIds: [String]?
    let channelMutes: [MutedChannelPayload]?
    let createdAt: Date
    let custom: [String: RawJSON]
    let deactivatedAt: Date?
    let deletedAt: Date?
    let devices: [Device]?
    let id: String
    let image: String?
    let invisible: Bool?
    let language: String?
    let lastActive: Date?
    let latestHiddenChannels: [String]?
    let mutes: [MutedUserPayload]?
    let name: String?
    let online: Bool
    let privacySettings: UserPrivacySettings?
    let pushPreferences: PushPreference?
    let revokeTokensIssuedBefore: Date?
    let role: String
    let teams: [String]?
    let teamsRole: [String: String]?
    let totalUnreadCount: Int?
    let totalUnreadCountByTeam: [String: Int]?
    let unreadChannels: Int?
    let unreadThreads: Int?
    let updatedAt: Date

    init(
        avgResponseTime: Int? = nil,
        banned: Bool? = nil,
        blockedUserIds: [String]? = nil,
        channelMutes: [MutedChannelPayload]? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        devices: [Device]? = nil,
        id: String,
        image: String? = nil,
        invisible: Bool? = nil,
        language: String? = nil,
        lastActive: Date? = nil,
        latestHiddenChannels: [String]? = nil,
        mutes: [MutedUserPayload]? = nil,
        name: String? = nil,
        online: Bool,
        privacySettings: UserPrivacySettings? = nil,
        pushPreferences: PushPreference? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String]? = nil,
        teamsRole: [String: String]? = nil,
        totalUnreadCount: Int? = nil,
        totalUnreadCountByTeam: [String: Int]? = nil,
        unreadChannels: Int? = nil,
        unreadThreads: Int? = nil,
        updatedAt: Date
    ) {
        self.avgResponseTime = avgResponseTime
        self.banned = banned
        self.blockedUserIds = blockedUserIds
        self.channelMutes = channelMutes
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.devices = devices
        self.id = id
        self.image = image
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.latestHiddenChannels = latestHiddenChannels
        self.mutes = mutes
        self.name = name
        self.online = online
        self.privacySettings = privacySettings
        self.pushPreferences = pushPreferences
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
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
        case deletedAt = "deleted_at"
        case devices
        case id
        case image
        case invisible
        case language
        case lastActive = "last_active"
        case latestHiddenChannels = "latest_hidden_channels"
        case mutes
        case name
        case online
        case privacySettings = "privacy_settings"
        case pushPreferences = "push_preferences"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
        case teamsRole = "teams_role"
        case totalUnreadCount = "total_unread_count"
        case totalUnreadCountByTeam = "total_unread_count_by_team"
        case unreadChannels = "unread_channels"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
            .union(UserPayloadsCodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        avgResponseTime = try container.decodeIfPresent(Int.self, forKey: .avgResponseTime)
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned)
        blockedUserIds = try container.decodeIfPresent([String].self, forKey: .blockedUserIds)
        channelMutes = try container.decodeIfPresent(
            [MutedChannelPayload].self,
            forKey: .channelMutes
        )
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        devices = try container.decodeIfPresent([Device].self, forKey: .devices)
        id = try container.decode(String.self, forKey: .id)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        latestHiddenChannels = try container.decodeIfPresent(
            [String].self,
            forKey: .latestHiddenChannels
        )
        mutes = try container.decodeIfPresent([MutedUserPayload].self, forKey: .mutes)
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
        revokeTokensIssuedBefore = try container.decodeIfPresent(
            Date.self,
            forKey: .revokeTokensIssuedBefore
        )
        role = try container.decode(String.self, forKey: .role)
        teams = try container.decodeIfPresent([String].self, forKey: .teams)
        teamsRole = try container.decodeIfPresent([String: String].self, forKey: .teamsRole)
        totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount)
        totalUnreadCountByTeam = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .totalUnreadCountByTeam
        )
        unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
        unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
