//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserResponse: Codable, Hashable {
    public var lastActive: String?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var deletedAt: String?
    
    public var invisible: Bool?
    
    public var language: String?
    
    public var revokeTokensIssuedBefore: String?
    
    public var updatedAt: String?
    
    public var deactivatedAt: String?
    
    public var online: Bool
    
    public var role: String
    
    public var shadowBanned: Bool
    
    public var teams: [String]?
    
    public var custom: [String: RawJSON]
    
    public var banExpires: String?
    
    public var banned: Bool
    
    public var createdAt: String?
    
    public var id: String
    
    public init(lastActive: String?, pushNotifications: StreamChatPushNotificationSettings?, deletedAt: String?, invisible: Bool?, language: String?, revokeTokensIssuedBefore: String?, updatedAt: String?, deactivatedAt: String?, online: Bool, role: String, shadowBanned: Bool, teams: [String]?, custom: [String: RawJSON], banExpires: String?, banned: Bool, createdAt: String?, id: String) {
        self.lastActive = lastActive
        
        self.pushNotifications = pushNotifications
        
        self.deletedAt = deletedAt
        
        self.invisible = invisible
        
        self.language = language
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.updatedAt = updatedAt
        
        self.deactivatedAt = deactivatedAt
        
        self.online = online
        
        self.role = role
        
        self.shadowBanned = shadowBanned
        
        self.teams = teams
        
        self.custom = custom
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.createdAt = createdAt
        
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastActive = "last_active"
        
        case pushNotifications = "push_notifications"
        
        case deletedAt = "deleted_at"
        
        case invisible
        
        case language
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case updatedAt = "updated_at"
        
        case deactivatedAt = "deactivated_at"
        
        case online
        
        case role
        
        case shadowBanned = "shadow_banned"
        
        case teams
        
        case custom = "Custom"
        
        case banExpires = "ban_expires"
        
        case banned
        
        case createdAt = "created_at"
        
        case id
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
    }
}
