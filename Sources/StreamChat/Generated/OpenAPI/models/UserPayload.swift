//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

class UserPayload: @unchecked Sendable, Codable, JSONEncodable {
    let avgResponseTime: Int?
    /// Whether a user is banned or not
    let banned: Bool?
    let blockedUserIds: [String]?
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
    let language: TranslationLanguage?
    /// Date of last activity
    let lastActive: Date?
    /// Optional name of user
    let name: String?
    /// Whether a user online or not
    let online: Bool
    /// Revocation date for tokens
    let revokeTokensIssuedBefore: Date?
    /// Determines the set of user permissions
    let role: UserRole
    /// List of teams user is a part of
    let teams: [String]?
    let teamsRole: [String: UserRole]?
    /// Date/time of the last update
    let updatedAt: Date

    init(
        avgResponseTime: Int? = nil,
        banned: Bool? = nil,
        blockedUserIds: [String]? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        language: TranslationLanguage? = nil,
        lastActive: Date? = nil,
        name: String? = nil,
        online: Bool,
        revokeTokensIssuedBefore: Date? = nil,
        role: UserRole,
        teams: [String]? = nil,
        teamsRole: [String: UserRole]? = nil,
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

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
            .union(UserPayloadsCodingKeys.allCases.map(\.rawValue))
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        avgResponseTime = try container.decodeIfPresent(Int.self, forKey: .avgResponseTime)
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned)
        blockedUserIds = try container.decodeIfPresent([String].self, forKey: .blockedUserIds)
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
        id = try container.decode(String.self, forKey: .id)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        language = try container.decodeIfPresent(TranslationLanguage.self, forKey: .language)
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        online = try container.decode(Bool.self, forKey: .online)
        revokeTokensIssuedBefore = try container.decodeIfPresent(Date.self, forKey: .revokeTokensIssuedBefore)
        role = try container.decode(UserRole.self, forKey: .role)
        teams = try container.decodeIfPresent([String].self, forKey: .teams)
        teamsRole = try container.decodeIfPresent([String: UserRole].self, forKey: .teamsRole)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
