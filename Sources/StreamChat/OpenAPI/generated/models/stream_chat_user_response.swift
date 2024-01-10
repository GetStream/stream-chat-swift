//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserResponse: Codable, Hashable {
    public var role: String
    
    public var shadowBanned: Bool
    
    public var createdAt: String?
    
    public var invisible: Bool?
    
    public var language: String?
    
    public var revokeTokensIssuedBefore: String?
    
    public var banExpires: String?
    
    public var deactivatedAt: String?
    
    public var id: String
    
    public var teams: [String]?
    
    public var custom: [String: RawJSON]
    
    public var deletedAt: String?
    
    public var online: Bool
    
    public var banned: Bool
    
    public var lastActive: String?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var updatedAt: String?
    
    public init(role: String, shadowBanned: Bool, createdAt: String?, invisible: Bool?, language: String?, revokeTokensIssuedBefore: String?, banExpires: String?, deactivatedAt: String?, id: String, teams: [String]?, custom: [String: RawJSON], deletedAt: String?, online: Bool, banned: Bool, lastActive: String?, pushNotifications: StreamChatPushNotificationSettings?, updatedAt: String?) {
        self.role = role
        
        self.shadowBanned = shadowBanned
        
        self.createdAt = createdAt
        
        self.invisible = invisible
        
        self.language = language
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.banExpires = banExpires
        
        self.deactivatedAt = deactivatedAt
        
        self.id = id
        
        self.teams = teams
        
        self.custom = custom
        
        self.deletedAt = deletedAt
        
        self.online = online
        
        self.banned = banned
        
        self.lastActive = lastActive
        
        self.pushNotifications = pushNotifications
        
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case role
        
        case shadowBanned = "shadow_banned"
        
        case createdAt = "created_at"
        
        case invisible
        
        case language
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case banExpires = "ban_expires"
        
        case deactivatedAt = "deactivated_at"
        
        case id
        
        case teams
        
        case custom = "Custom"
        
        case deletedAt = "deleted_at"
        
        case online
        
        case banned
        
        case lastActive = "last_active"
        
        case pushNotifications = "push_notifications"
        
        case updatedAt = "updated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
