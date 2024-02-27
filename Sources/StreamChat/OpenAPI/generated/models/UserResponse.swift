//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserResponse: Codable, Hashable {
    public var banned: Bool
    public var id: String
    public var online: Bool
    public var role: String
    public var shadowBanned: Bool
    public var custom: [String: RawJSON]
    public var banExpires: Date? = nil
    public var createdAt: Date? = nil
    public var deactivatedAt: Date? = nil
    public var deletedAt: Date? = nil
    public var invisible: Bool? = nil
    public var language: String? = nil
    public var lastActive: Date? = nil
    public var revokeTokensIssuedBefore: Date? = nil
    public var updatedAt: Date? = nil
    public var teams: [String]? = nil
    public var pushNotifications: PushNotificationSettings? = nil

    public init(banned: Bool, id: String, online: Bool, role: String, shadowBanned: Bool, custom: [String: RawJSON], banExpires: Date? = nil, createdAt: Date? = nil, deactivatedAt: Date? = nil, deletedAt: Date? = nil, invisible: Bool? = nil, language: String? = nil, lastActive: Date? = nil, revokeTokensIssuedBefore: Date? = nil, updatedAt: Date? = nil, teams: [String]? = nil, pushNotifications: PushNotificationSettings? = nil) {
        self.banned = banned
        self.id = id
        self.online = online
        self.role = role
        self.shadowBanned = shadowBanned
        self.custom = custom
        self.banExpires = banExpires
        self.createdAt = createdAt
        self.deactivatedAt = deactivatedAt
        self.deletedAt = deletedAt
        self.invisible = invisible
        self.language = language
        self.lastActive = lastActive
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.updatedAt = updatedAt
        self.teams = teams
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case id
        case online
        case role
        case shadowBanned = "shadow_banned"
        case custom
        case banExpires = "ban_expires"
        case createdAt = "created_at"
        case deactivatedAt = "deactivated_at"
        case deletedAt = "deleted_at"
        case invisible
        case language
        case lastActive = "last_active"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case updatedAt = "updated_at"
        case teams
        case pushNotifications = "push_notifications"
    }
}