//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObject: Codable, Hashable {
    public var banExpires: Date?
    
    public var banned: Bool?
    
    public var revokeTokensIssuedBefore: Date?
    
    public var lastActive: Date?
    
    public var role: String?
    
    public var teams: [String]?
    
    public var custom: [String: RawJSON]?
    
    public var createdAt: Date?
    
    public var deletedAt: Date?
    
    public var invisible: Bool?
    
    public var language: String?
    
    public var updatedAt: Date?
    
    public var deactivatedAt: Date?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var id: String
    
    public var online: Bool?
    
    public init(banExpires: Date?, banned: Bool?, revokeTokensIssuedBefore: Date?, lastActive: Date?, role: String?, teams: [String]?, custom: [String: RawJSON]?, createdAt: Date?, deletedAt: Date?, invisible: Bool?, language: String?, updatedAt: Date?, deactivatedAt: Date?, pushNotifications: StreamChatPushNotificationSettings?, id: String, online: Bool?) {
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.lastActive = lastActive
        
        self.role = role
        
        self.teams = teams
        
        self.custom = custom
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.invisible = invisible
        
        self.language = language
        
        self.updatedAt = updatedAt
        
        self.deactivatedAt = deactivatedAt
        
        self.pushNotifications = pushNotifications
        
        self.id = id
        
        self.online = online
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        
        case banned
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case lastActive = "last_active"
        
        case role
        
        case teams
        
        case custom = "Custom"
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case invisible
        
        case language
        
        case updatedAt = "updated_at"
        
        case deactivatedAt = "deactivated_at"
        
        case pushNotifications = "push_notifications"
        
        case id
        
        case online
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(online, forKey: .online)
    }
}
