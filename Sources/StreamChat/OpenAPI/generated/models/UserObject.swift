//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserObject: Codable, Hashable {
    public var id: String
    public var banExpires: Date? = nil
    public var banned: Bool? = nil
    public var createdAt: Date? = nil
    public var deactivatedAt: Date? = nil
    public var deletedAt: Date? = nil
    public var invisible: Bool? = nil
    public var language: String? = nil
    public var lastActive: Date? = nil
    public var online: Bool? = nil
    public var revokeTokensIssuedBefore: Date? = nil
    public var role: String? = nil
    public var updatedAt: Date? = nil
    public var teams: [String]? = nil
    public var custom: [String: RawJSON]? = nil
    public var pushNotifications: PushNotificationSettings? = nil

    public init(id: String, banExpires: Date? = nil, banned: Bool? = nil, createdAt: Date? = nil, deactivatedAt: Date? = nil, deletedAt: Date? = nil, invisible: Bool? = nil, language: String? = nil, lastActive: Date? = nil, online: Bool? = nil, revokeTokensIssuedBefore: Date? = nil, role: String? = nil, updatedAt: Date? = nil, teams: [String]? = nil, custom: [String: RawJSON]? = nil, pushNotifications: PushNotificationSettings? = nil) {
        self.id = id
        self.banExpires = banExpires
        self.banned = banned
        self.createdAt = createdAt
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.online = online
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.role = role
        self.updatedAt = updatedAt
        self.teams = teams
        self.custom = custom
        self.pushNotifications = pushNotifications
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case banExpires = "ban_expires"
        case banned
        case createdAt = "created_at"
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case invisible
        case language
        case lastActive = "last_active"
        case online
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case role
        case updatedAt = "updated_at"
        case teams
        case custom
        case pushNotifications = "push_notifications"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(banExpires, forKey: .banExpires)
        try container.encode(banned, forKey: .banned)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        try container.encode(deletedAt, forKey: .deletedAt)
        try container.encode(invisible, forKey: .invisible)
        try container.encode(language, forKey: .language)
        try container.encode(lastActive, forKey: .lastActive)
        try container.encode(online, forKey: .online)
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        try container.encode(role, forKey: .role)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(teams, forKey: .teams)
        try container.encode(custom, forKey: .custom)
        try container.encode(pushNotifications, forKey: .pushNotifications)
    }
}
