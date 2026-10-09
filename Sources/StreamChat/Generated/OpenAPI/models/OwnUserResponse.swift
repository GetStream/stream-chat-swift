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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.avgResponseTime = try container.decodeIfPresent(Int.self, forKey: .avgResponseTime)
        self.banned = try container.decodeIfPresent(Bool.self, forKey: .banned) ?? false
        self.blockedUserIds = try container.decodeIfPresent([String].self, forKey: .blockedUserIds)
        self.channelMutes = try container.decodeArrayIgnoringFailures(
            [MutedChannelPayload].self,
            forKey: .channelMutes
        )
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        self.devices = try container.decodeArrayIgnoringFailures([Device].self, forKey: .devices)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible) ?? false
        self.language = try container.decodeIfPresent(String.self, forKey: .language) ?? ""
        self.lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        self.mutes = try container.decodeArrayIgnoringFailures(
            [MutedUserPayload].self,
            forKey: .mutes
        )
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.online = try container.decode(Bool.self, forKey: .online)
        self.privacySettings = try container.decodeIfPresent(
            UserPrivacySettings.self,
            forKey: .privacySettings
        )
        self.pushPreferences = try container.decodeIfPresent(
            PushPreference.self,
            forKey: .pushPreferences
        )
        self.role = try container.decode(String.self, forKey: .role)
        self.teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        self.teamsRole = try container.decodeIfPresent([String: String].self, forKey: .teamsRole)
        self.totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
        self.totalUnreadCountByTeam = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .totalUnreadCountByTeam
        )
        self.unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
        self.unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads) ?? 0
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
