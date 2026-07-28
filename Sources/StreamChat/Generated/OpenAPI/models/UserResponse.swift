//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserResponse: Sendable, Codable, JSONEncodable {
    let avgResponseTime: Int?
    /// Whether a user is banned or not
    let banned: Bool
    let blockedUserIds: [String]
    /// Date/time of creation
    let createdAt: Date
    /// Custom data for this object
    let custom: [String: RawJSON]
    /// Date of deactivation
    let deactivatedAt: Date?
    /// Date/time of deletion
    let deletedAt: Date?
    /// Unique user identifier
    let id: String
    let image: String?
    /// Preferred language of a user
    let language: String
    /// Date of last activity
    let lastActive: Date?
    /// Optional name of user
    let name: String?
    /// Whether a user online or not
    let online: Bool
    /// Revocation date for tokens
    let revokeTokensIssuedBefore: Date?
    /// Determines the set of user permissions
    let role: String
    /// List of teams user is a part of
    let teams: [String]
    let teamsRole: [String: String]?
    /// Date/time of the last update
    let updatedAt: Date

    init(
        avgResponseTime: Int? = nil,
        banned: Bool,
        blockedUserIds: [String],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        online: Bool,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String],
        teamsRole: [String: String]? = nil,
        updatedAt: Date
    ) {
        self.avgResponseTime = avgResponseTime
        self.banned = banned
        self.blockedUserIds = blockedUserIds
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.id = id
        self.image = image
        self.language = language
        self.lastActive = lastActive
        self.name = name
        self.online = online
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.teams = teams
        self.teamsRole = teamsRole
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case avgResponseTime = "avg_response_time"
        case banned
        case blockedUserIds = "blocked_user_ids"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case id
        case image
        case language
        case lastActive = "last_active"
        case name
        case online
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case teams
        case teamsRole = "teams_role"
        case updatedAt = "updated_at"
    }
}
