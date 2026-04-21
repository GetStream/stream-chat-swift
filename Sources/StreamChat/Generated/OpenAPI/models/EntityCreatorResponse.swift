//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EntityCreatorResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var avgResponseTime: Int?
    /// Number of minor actions performed on the user
    var banCount: Int
    var banned: Bool
    var blockedUserIds: [String]
    var createdAt: Date
    var custom: [String: RawJSON]
    var deactivatedAt: Date?
    var deletedAt: Date?
    /// Number of major actions performed on the user
    var deletedContentCount: Int
    /// Number of flag actions performed on the user
    var flaggedCount: Int
    var id: String
    var image: String?
    var language: String
    var lastActive: Date?
    var name: String?
    var online: Bool
    var revokeTokensIssuedBefore: Date?
    var role: String
    var teams: [String]
    var teamsRole: [String: String]?
    var updatedAt: Date

    init(avgResponseTime: Int? = nil, banCount: Int, banned: Bool, blockedUserIds: [String], createdAt: Date, custom: [String: RawJSON], deactivatedAt: Date? = nil, deletedAt: Date? = nil, deletedContentCount: Int, flaggedCount: Int, id: String, image: String? = nil, language: String, lastActive: Date? = nil, name: String? = nil, online: Bool, revokeTokensIssuedBefore: Date? = nil, role: String, teams: [String], teamsRole: [String: String]? = nil, updatedAt: Date) {
        self.avgResponseTime = avgResponseTime
        self.banCount = banCount
        self.banned = banned
        self.blockedUserIds = blockedUserIds
        self.createdAt = createdAt
        self.custom = custom
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.deletedContentCount = deletedContentCount
        self.flaggedCount = flaggedCount
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
        case banCount = "ban_count"
        case banned
        case blockedUserIds = "blocked_user_ids"
        case createdAt = "created_at"
        case custom
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case deletedContentCount = "deleted_content_count"
        case flaggedCount = "flagged_count"
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

    static func == (lhs: EntityCreatorResponse, rhs: EntityCreatorResponse) -> Bool {
        lhs.avgResponseTime == rhs.avgResponseTime &&
            lhs.banCount == rhs.banCount &&
            lhs.banned == rhs.banned &&
            lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deactivatedAt == rhs.deactivatedAt &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.deletedContentCount == rhs.deletedContentCount &&
            lhs.flaggedCount == rhs.flaggedCount &&
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
        hasher.combine(banCount)
        hasher.combine(banned)
        hasher.combine(blockedUserIds)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deactivatedAt)
        hasher.combine(deletedAt)
        hasher.combine(deletedContentCount)
        hasher.combine(flaggedCount)
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
