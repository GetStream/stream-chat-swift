//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var avgResponseTime: Int?
    /// Whether a user is banned or not
    var banned: Bool
    var blockedUserIds: [String]
    /// Date/time of creation
    var createdAt: Date
    /// Custom data for this object
    var custom: [String: RawJSON]
    /// Date of deactivation
    var deactivatedAt: Date?
    /// Date/time of deletion
    var deletedAt: Date?
    /// Unique user identifier
    var id: String
    var image: String?
    /// Preferred language of a user
    var language: String
    /// Date of last activity
    var lastActive: Date?
    /// Optional name of user
    var name: String?
    /// Whether a user online or not
    var online: Bool
    /// Revocation date for tokens
    var revokeTokensIssuedBefore: Date?
    /// Determines the set of user permissions
    var role: String
    /// List of teams user is a part of
    var teams: [String]
    var teamsRole: [String: String]?
    /// Date/time of the last update
    var updatedAt: Date

    init(avgResponseTime: Int? = nil, banned: Bool, blockedUserIds: [String], createdAt: Date, custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, id: String, image: String? = nil, language: String, lastActive: Date? = nil, name: String? = nil, online: Bool, revokeTokensIssuedBefore: Date? = nil, role: String, teams: [String], teamsRole: [String: String]? = nil, updatedAt: Date) {
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

    static func == (lhs: UserResponse, rhs: UserResponse) -> Bool {
        lhs.avgResponseTime == rhs.avgResponseTime &&
            lhs.banned == rhs.banned &&
            lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deactivatedAt == rhs.deactivatedAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.language == rhs.language &&
            lhs.lastActive == rhs.lastActive &&
            lhs.name == rhs.name &&
            lhs.online == rhs.online &&
            lhs.revokeTokensIssuedBefore == rhs.revokeTokensIssuedBefore &&
            lhs.role == rhs.role &&
            lhs.teams == rhs.teams &&
            lhs.teamsRole == rhs.teamsRole &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(avgResponseTime)
        hasher.combine(banned)
        hasher.combine(blockedUserIds)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deactivatedAt)
        hasher.combine(deletedAt)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(language)
        hasher.combine(lastActive)
        hasher.combine(name)
        hasher.combine(online)
        hasher.combine(revokeTokensIssuedBefore)
        hasher.combine(role)
        hasher.combine(teams)
        hasher.combine(teamsRole)
        hasher.combine(updatedAt)
    }
}
