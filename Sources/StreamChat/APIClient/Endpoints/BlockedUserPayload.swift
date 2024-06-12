//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming blocking user JSON payload.
struct BlockingUserPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case blockedUserId = "blocked_user_id"
        case blockedByUserId = "blocked_by_user_id"
        case createdAt = "created_at"
    }

    let blockedUserId: String
    let blockedByUserId: String
    let createdAt: Date
}

extension BlockingUserPayload: Equatable {
    static func == (lhs: BlockingUserPayload, rhs: BlockingUserPayload) -> Bool {
        lhs.blockedUserId == rhs.blockedUserId &&
        lhs.blockedByUserId == rhs.blockedByUserId &&
        lhs.createdAt == rhs.createdAt
    }
}

/// An object describing the incoming blocked users JSON payload.
struct BlocksPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case blockedUsers = "blocks"
    }

    /// The blocked users.
    let blockedUsers: [BlockPayload]
}

/// An object describing the incoming block JSON payload.
struct BlockPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case blockedUserId = "blocked_user_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case blockedUser = "blocked_user"
    }

    let blockedUserId: String
    let userId: String
    let createdAt: Date
    let blockedUser: BlockedUserPayload
}

extension BlockPayload: Equatable {
    static func == (lhs: BlockPayload, rhs: BlockPayload) -> Bool {
        lhs.blockedUserId == rhs.blockedUserId &&
        lhs.userId == rhs.userId &&
        lhs.createdAt == rhs.createdAt
    }
}

/// An object describing the incoming blocked-user JSON payload.
struct BlockedUserPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isBanned = "banned"
        case lastActiveAt = "last_active"
        case privacySettings = "privacy_settings"
        case imageURL = "image"
        case language = "language"
        case role = "role"
        case teams = "teams"
        case isOnline = "online"
    }

    let id: String
    let name: String?
    let createdAt: Date
    let updatedAt: Date
    let isBanned: Bool
    let lastActiveAt: Date?
    let privacySettings: UserPrivacySettingsPayload?
    let imageURL: URL?
    let language: String?
    let role: UserRole
    let teams: [TeamId]
    let isOnline: Bool
}
