//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class OwnUserResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var avgResponseTime: Int?
    var banned: Bool
    var blockedUserIds: [String]?
    var channelMutes: [ChannelMute]
    var createdAt: Date
    var custom: [String: RawJSON]
    var deactivatedAt: Date?
    var deletedAt: Date?
    var devices: [DeviceResponse]
    var id: String
    var image: String?
    var invisible: Bool
    var language: String
    var lastActive: Date?
    var latestHiddenChannels: [String]?
    var mutes: [UserMuteResponse]
    var name: String?
    var online: Bool
    var privacySettings: PrivacySettingsResponse?
    var pushPreferences: PushPreferencesResponse?
    var revokeTokensIssuedBefore: Date?
    var role: String
    var teams: [String]
    var teamsRole: [String: String]?
    var totalUnreadCount: Int
    var totalUnreadCountByTeam: [String: Int]?
    var unreadChannels: Int
    var unreadCount: Int
    var unreadThreads: Int
    var updatedAt: Date

    init(avgResponseTime: Int? = nil, banned: Bool, blockedUserIds: [String]? = nil, channelMutes: [ChannelMute], createdAt: Date, custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, devices: [DeviceResponse], id: String, image: String? = nil, invisible: Bool, language: String, lastActive: Date? = nil, latestHiddenChannels: [String]? = nil, mutes: [UserMuteResponse], name: String? = nil, online: Bool, privacySettings: PrivacySettingsResponse? = nil, pushPreferences: PushPreferencesResponse? = nil, revokeTokensIssuedBefore: Date? = nil, role: String, teams: [String], teamsRole: [String: String]? = nil, totalUnreadCount: Int, totalUnreadCountByTeam: [String: Int]? = nil, unreadChannels: Int, unreadCount: Int, unreadThreads: Int, updatedAt: Date) {
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
        self.unreadCount = unreadCount
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
        case unreadCount = "unread_count"
        case unreadThreads = "unread_threads"
        case updatedAt = "updated_at"
    }

    static func == (lhs: OwnUserResponse, rhs: OwnUserResponse) -> Bool {
        lhs.avgResponseTime == rhs.avgResponseTime &&
            lhs.banned == rhs.banned &&
            lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.channelMutes == rhs.channelMutes &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deactivatedAt == rhs.deactivatedAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.devices == rhs.devices &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.invisible == rhs.invisible &&
            lhs.language == rhs.language &&
            lhs.lastActive == rhs.lastActive &&
            lhs.latestHiddenChannels == rhs.latestHiddenChannels &&
            lhs.mutes == rhs.mutes &&
            lhs.name == rhs.name &&
            lhs.online == rhs.online &&
            lhs.privacySettings == rhs.privacySettings &&
            lhs.pushPreferences == rhs.pushPreferences &&
            lhs.revokeTokensIssuedBefore == rhs.revokeTokensIssuedBefore &&
            lhs.role == rhs.role &&
            lhs.teams == rhs.teams &&
            lhs.teamsRole == rhs.teamsRole &&
            lhs.totalUnreadCount == rhs.totalUnreadCount &&
            lhs.totalUnreadCountByTeam == rhs.totalUnreadCountByTeam &&
            lhs.unreadChannels == rhs.unreadChannels &&
            lhs.unreadCount == rhs.unreadCount &&
            lhs.unreadThreads == rhs.unreadThreads &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(avgResponseTime)
        hasher.combine(banned)
        hasher.combine(blockedUserIds)
        hasher.combine(channelMutes)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deactivatedAt)
        hasher.combine(deletedAt)
        hasher.combine(devices)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(invisible)
        hasher.combine(language)
        hasher.combine(lastActive)
        hasher.combine(latestHiddenChannels)
        hasher.combine(mutes)
        hasher.combine(name)
        hasher.combine(online)
        hasher.combine(privacySettings)
        hasher.combine(pushPreferences)
        hasher.combine(revokeTokensIssuedBefore)
        hasher.combine(role)
        hasher.combine(teams)
        hasher.combine(teamsRole)
        hasher.combine(totalUnreadCount)
        hasher.combine(totalUnreadCountByTeam)
        hasher.combine(unreadChannels)
        hasher.combine(unreadCount)
        hasher.combine(unreadThreads)
        hasher.combine(updatedAt)
    }
}
