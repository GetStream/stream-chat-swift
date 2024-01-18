//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObject: Codable, Hashable {
    public var language: String?
    
    public var deletedAt: Date?
    
    public var lastActive: Date?
    
    public var online: Bool
    
    public var revokeTokensIssuedBefore: Date?
    
    public var banned: Bool
    
    public var createdAt: Date?
    
    public var deactivatedAt: Date?
    
    public var id: String
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var role: String
    
    public var custom: [String: RawJSON]?
    
    public var invisible: Bool?
    
    public var teams: [String]?
    
    public var updatedAt: Date?
    
    public var banExpires: Date?
    
    public var imageURL: String?
    
    public init(language: String?, deletedAt: Date?, lastActive: Date?, online: Bool, revokeTokensIssuedBefore: Date?, banned: Bool, createdAt: Date?, deactivatedAt: Date?, id: String, pushNotifications: StreamChatPushNotificationSettings?, role: String, custom: [String: RawJSON], invisible: Bool?, teams: [String]?, updatedAt: Date?, banExpires: Date?) {
        self.language = language
        
        self.deletedAt = deletedAt
        
        self.lastActive = lastActive
        
        self.online = online
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.banned = banned
        
        self.createdAt = createdAt
        
        self.deactivatedAt = deactivatedAt
        
        self.id = id
        
        self.pushNotifications = pushNotifications
        
        self.role = role
        
        self.custom = custom
        
        self.invisible = invisible
        
        self.teams = teams
        
        self.updatedAt = updatedAt
        
        self.banExpires = banExpires
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case language
        
        case deletedAt = "deleted_at"
        
        case lastActive = "last_active"
        
        case online
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case banned
        
        case createdAt = "created_at"
        
        case deactivatedAt = "deactivated_at"
        
        case id
        
        case pushNotifications = "push_notifications"
        
        case role
        
        case custom = "Custom"
        
        case invisible
        
        case teams
        
        case updatedAt = "updated_at"
        
        case banExpires = "ban_expires"
        
        case imageURL = "image_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(banExpires, forKey: .banExpires)
    }
}
