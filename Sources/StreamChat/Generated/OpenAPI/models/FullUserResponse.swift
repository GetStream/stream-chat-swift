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
    /// The privacy settings of the user.
    let privacySettings: UserPrivacySettings?
    let role: String
    let shadowBanned: Bool
    let teams: [String]
    let teamsRole: [String: String]?
    let totalUnreadCount: Int
    let unreadChannels: Int
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
        shadowBanned: Bool,
        teams: [String],
        teamsRole: [String: String]? = nil,
        totalUnreadCount: Int,
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
        self.role = role
        self.shadowBanned = shadowBanned
        self.teams = teams
        self.teamsRole = teamsRole
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadThreads = unreadThreads
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
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
        self.shadowBanned = try container.decode(Bool.self, forKey: .shadowBanned)
        self.teams = try container.decode([String].self, forKey: .teams)
        self.teamsRole = try container.decodeIfPresent([String: String].self, forKey: .teamsRole)
        self.totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
        self.unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
        self.unreadThreads = try container.decode(Int.self, forKey: .unreadThreads)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
