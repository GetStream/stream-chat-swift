//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserResponse: Codable, Hashable {
    public var banExpires: Date?
    
    public var banned: Bool
    
    public var teams: [String]?
    
    public var deactivatedAt: Date?
    
    public var online: Bool
    
    public var shadowBanned: Bool
    
    public var updatedAt: Date?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var custom: [String: RawJSON]
    
    public var deletedAt: Date?
    
    public var language: String?
    
    public var lastActive: Date?
    
    public var role: String
    
    public var createdAt: Date?
    
    public var id: String
    
    public var invisible: Bool?
    
    public var revokeTokensIssuedBefore: Date?
    
    public init(banExpires: Date?, banned: Bool, teams: [String]?, deactivatedAt: Date?, online: Bool, shadowBanned: Bool, updatedAt: Date?, pushNotifications: StreamChatPushNotificationSettings?, custom: [String: RawJSON], deletedAt: Date?, language: String?, lastActive: Date?, role: String, createdAt: Date?, id: String, invisible: Bool?, revokeTokensIssuedBefore: Date?) {
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.teams = teams
        
        self.deactivatedAt = deactivatedAt
        
        self.online = online
        
        self.shadowBanned = shadowBanned
        
        self.updatedAt = updatedAt
        
        self.pushNotifications = pushNotifications
        
        self.custom = custom
        
        self.deletedAt = deletedAt
        
        self.language = language
        
        self.lastActive = lastActive
        
        self.role = role
        
        self.createdAt = createdAt
        
        self.id = id
        
        self.invisible = invisible
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        
        case banned
        
        case teams
        
        case deactivatedAt = "deactivated_at"
        
        case online
        
        case shadowBanned = "shadow_banned"
        
        case updatedAt = "updated_at"
        
        case pushNotifications = "push_notifications"
        
        case custom = "Custom"
        
        case deletedAt = "deleted_at"
        
        case language
        
        case lastActive = "last_active"
        
        case role
        
        case createdAt = "created_at"
        
        case id
        
        case invisible
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
    }
}
