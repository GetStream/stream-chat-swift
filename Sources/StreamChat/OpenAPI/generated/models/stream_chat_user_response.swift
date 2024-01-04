//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserResponse: Codable, Hashable {
    public var revokeTokensIssuedBefore: String?
    
    public var updatedAt: String?
    
    public var custom: [String: RawJSON]
    
    public var createdAt: String?
    
    public var invisible: Bool?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var deletedAt: String?
    
    public var lastActive: String?
    
    public var teams: [String]?
    
    public var banExpires: String?
    
    public var banned: Bool
    
    public var language: String?
    
    public var role: String
    
    public var deactivatedAt: String?
    
    public var id: String
    
    public var online: Bool
    
    public var shadowBanned: Bool
    
    public init(revokeTokensIssuedBefore: String?, updatedAt: String?, custom: [String: RawJSON], createdAt: String?, invisible: Bool?, pushNotifications: StreamChatPushNotificationSettings?, deletedAt: String?, lastActive: String?, teams: [String]?, banExpires: String?, banned: Bool, language: String?, role: String, deactivatedAt: String?, id: String, online: Bool, shadowBanned: Bool) {
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.updatedAt = updatedAt
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.invisible = invisible
        
        self.pushNotifications = pushNotifications
        
        self.deletedAt = deletedAt
        
        self.lastActive = lastActive
        
        self.teams = teams
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.language = language
        
        self.role = role
        
        self.deactivatedAt = deactivatedAt
        
        self.id = id
        
        self.online = online
        
        self.shadowBanned = shadowBanned
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case updatedAt = "updated_at"
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case invisible
        
        case pushNotifications = "push_notifications"
        
        case deletedAt = "deleted_at"
        
        case lastActive = "last_active"
        
        case teams
        
        case banExpires = "ban_expires"
        
        case banned
        
        case language
        
        case role
        
        case deactivatedAt = "deactivated_at"
        
        case id
        
        case online
        
        case shadowBanned = "shadow_banned"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
    }
}
