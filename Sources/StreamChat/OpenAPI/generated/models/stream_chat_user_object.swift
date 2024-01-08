//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObject: Codable, Hashable {
    public var deactivatedAt: String?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var teams: [String]?
    
    public var lastActive: String?
    
    public var role: String?
    
    public var updatedAt: String?
    
    public var custom: [String: RawJSON]?
    
    public var deletedAt: String?
    
    public var language: String?
    
    public var online: Bool?
    
    public var banExpires: String?
    
    public var banned: Bool?
    
    public var createdAt: String?
    
    public var id: String
    
    public var invisible: Bool?
    
    public var revokeTokensIssuedBefore: String?
    
    public init(deactivatedAt: String?, pushNotifications: StreamChatPushNotificationSettings?, teams: [String]?, lastActive: String?, role: String?, updatedAt: String?, custom: [String: RawJSON]?, deletedAt: String?, language: String?, online: Bool?, banExpires: String?, banned: Bool?, createdAt: String?, id: String, invisible: Bool?, revokeTokensIssuedBefore: String?) {
        self.deactivatedAt = deactivatedAt
        
        self.pushNotifications = pushNotifications
        
        self.teams = teams
        
        self.lastActive = lastActive
        
        self.role = role
        
        self.updatedAt = updatedAt
        
        self.custom = custom
        
        self.deletedAt = deletedAt
        
        self.language = language
        
        self.online = online
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.createdAt = createdAt
        
        self.id = id
        
        self.invisible = invisible
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case deactivatedAt = "deactivated_at"
        
        case pushNotifications = "push_notifications"
        
        case teams
        
        case lastActive = "last_active"
        
        case role
        
        case updatedAt = "updated_at"
        
        case custom = "Custom"
        
        case deletedAt = "deleted_at"
        
        case language
        
        case online
        
        case banExpires = "ban_expires"
        
        case banned
        
        case createdAt = "created_at"
        
        case id
        
        case invisible
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
    }
}
