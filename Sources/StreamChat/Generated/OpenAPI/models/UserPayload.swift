//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// User response object
final class UserPayload: Sendable, Codable, JSONEncodable {
    let avgResponseTime: Int?
    /// Whether a user is banned or not
    let banned: Bool
    let blockedUserIds: [String]?
    /// Date/time of creation
    let createdAt: Date
    /// Custom data for this object
    let custom: [String: RawJSON]
    /// Date of deactivation
    let deactivatedAt: Date?
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
        blockedUserIds: [String]? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        id: String,
        image: String? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        online: Bool,
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
        self.id = id
        self.image = image
        self.language = language
        self.lastActive = lastActive
        self.name = name
        self.online = online
        self.role = role
        self.teams = teams
        self.teamsRole = teamsRole
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.avgResponseTime = try container.decodeIfPresent(Int.self, forKey: .avgResponseTime)
        self.banned = try container.decodeIfPresent(Bool.self, forKey: .banned) ?? false
        self.blockedUserIds = try container.decodeIfPresent([String].self, forKey: .blockedUserIds)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.language = try container.decodeIfPresent(String.self, forKey: .language) ?? ""
        self.lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.online = try container.decode(Bool.self, forKey: .online)
        self.role = try container.decode(String.self, forKey: .role)
        self.teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        self.teamsRole = try container.decodeIfPresent([String: String].self, forKey: .teamsRole)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(avgResponseTime, forKey: .avgResponseTime)
        try container.encode(banned, forKey: .banned)
        try container.encodeIfPresent(blockedUserIds, forKey: .blockedUserIds)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(deactivatedAt, forKey: .deactivatedAt)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(lastActive, forKey: .lastActive)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(online, forKey: .online)
        try container.encode(role, forKey: .role)
        try container.encode(teams, forKey: .teams)
        try container.encodeIfPresent(teamsRole, forKey: .teamsRole)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
