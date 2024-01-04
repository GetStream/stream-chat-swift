//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObject: Codable, Hashable {
    public var banned: Bool?
    
    public var teams: [String]?
    
    public var custom: [String: RawJSON]?
    
    public var createdAt: String?
    
    public var lastActive: String?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var role: String?
    
    public var updatedAt: String?
    
    public var banExpires: String?
    
    public var id: String
    
    public var language: String?
    
    public var online: Bool?
    
    public var revokeTokensIssuedBefore: String?
    
    public var deactivatedAt: String?
    
    public var invisible: Bool?
    
    public var deletedAt: String?
    
    public init(banned: Bool?, teams: [String]?, custom: [String: RawJSON]?, createdAt: String?, lastActive: String?, pushNotifications: StreamChatPushNotificationSettings?, role: String?, updatedAt: String?, banExpires: String?, id: String, language: String?, online: Bool?, revokeTokensIssuedBefore: String?, deactivatedAt: String?, invisible: Bool?, deletedAt: String?) {
        self.banned = banned
        
        self.teams = teams
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.lastActive = lastActive
        
        self.pushNotifications = pushNotifications
        
        self.role = role
        
        self.updatedAt = updatedAt
        
        self.banExpires = banExpires
        
        self.id = id
        
        self.language = language
        
        self.online = online
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.deactivatedAt = deactivatedAt
        
        self.invisible = invisible
        
        self.deletedAt = deletedAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        
        case teams
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case lastActive = "last_active"
        
        case pushNotifications = "push_notifications"
        
        case role
        
        case updatedAt = "updated_at"
        
        case banExpires = "ban_expires"
        
        case id
        
        case language
        
        case online
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case deactivatedAt = "deactivated_at"
        
        case invisible
        
        case deletedAt = "deleted_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(deletedAt, forKey: .deletedAt)
    }
}
