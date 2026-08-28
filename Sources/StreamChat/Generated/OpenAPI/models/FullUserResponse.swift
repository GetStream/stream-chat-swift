//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FullUserResponse: Sendable, Decodable {
    let avgResponseTime: Int?
    let banExpires: Date?
    let banned: Bool
    let blockedUserIds: [String]
    let channelMutes: [MutedChannelPayload]
    let createdAt: Date
    let custom: [String: RawJSON]
    let deactivatedAt: Date?
    let deletedAt: Date?
    let devices: [Device]
    let id: String
    let image: String?
    let invisible: Bool
    let language: String
    let lastActive: Date?
    let latestHiddenChannels: [String]?
    let mutes: [MutedUserPayload]
    let name: String?
    let online: Bool
    let privacySettings: UserPrivacySettings?
    let revokeTokensIssuedBefore: Date?
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
        banExpires: Date? = nil,
        banned: Bool,
        blockedUserIds: [String],
        channelMutes: [MutedChannelPayload],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        devices: [Device],
        id: String,
        image: String? = nil,
        invisible: Bool,
        language: String,
        lastActive: Date? = nil,
        latestHiddenChannels: [String]? = nil,
        mutes: [MutedUserPayload],
        name: String? = nil,
        online: Bool,
        privacySettings: UserPrivacySettings? = nil,
        revokeTokensIssuedBefore: Date? = nil,
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
        self.banExpires = banExpires
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
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.shadowBanned = shadowBanned
        self.teams = teams
        self.teamsRole = teamsRole
        self.totalUnreadCount = totalUnreadCount
        self.unreadChannels = unreadChannels
        self.unreadThreads = unreadThreads
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case avgResponseTime = "avg_response_time"
        case banExpires = "ban_expires"
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
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case shadowBanned = "shadow_banned"
        case teams
        case teamsRole = "teams_role"
        case totalUnreadCount = "total_unread_count"
        case unreadChannels = "unread_channels"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }
}
