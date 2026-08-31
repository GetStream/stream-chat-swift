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
