//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum UserPayloadsCodingKeys: String, CodingKey, CaseIterable {
    case id
    case name
    case imageURL = "image"
    case role
    case isOnline = "online"
    case isBanned = "banned"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deactivatedAt = "deactivated_at"
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
    case unreadThreads = "unread_threads"
    case mutedUsers = "mutes"
    case mutedChannels = "channel_mutes"
    case isAnonymous = "anon"
    case devices
    case unreadCount = "unread_count"
    case language
    case privacySettings = "privacy_settings"
    case blockedUserIds = "blocked_user_ids"
    case teamsRole = "teams_role"
    case avgResponseTime = "avg_response_time"
    case pushPreference = "push_preferences"
}

// MARK: - GET users

/// An object describing the outgoing user JSON payload.
final class UserRequestBody: Encodable, Sendable {
    let id: String
    let name: String?
    let imageURL: URL?
    let extraData: [String: RawJSON]

    init(id: String, name: String?, imageURL: URL?, extraData: [String: RawJSON]) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserPayloadsCodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try extraData.encode(to: encoder)
    }
}

// MARK: - PATCH users

/// An object describing the incoming user JSON payload.
struct CurrentUserUpdateResponse: Decodable {
    let user: CurrentUserPayload

    enum CodingKeys: String, CodingKey {
        case users
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let users = try container.decode([String: CurrentUserPayload].self, forKey: .users)
        guard let user = users.first?.value else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.users], debugDescription: "Missing updated user.")
            )
        }
        self.user = user
    }

    init(user: CurrentUserPayload) {
        self.user = user
    }
}

/// An object describing the outgoing user JSON payload.
struct UserUpdateRequestBody: Encodable {
    let name: String?
    let imageURL: URL?
    let privacySettings: UserPrivacySettingsPayload?
    let role: UserRole?
    let extraData: [String: RawJSON]?
    let teamsRole: [TeamId: UserRole]?

    init(
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettingsPayload?,
        role: UserRole?,
        teamsRole: [TeamId: UserRole]?,
        extraData: [String: RawJSON]?
    ) {
        self.name = name
        self.imageURL = imageURL
        self.privacySettings = privacySettings
        self.role = role
        self.extraData = extraData
        self.teamsRole = teamsRole
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserPayloadsCodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(privacySettings, forKey: .privacySettings)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(teamsRole, forKey: .teamsRole)
        try extraData?.encode(to: encoder)
    }
}
