//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserResponse: Codable, Hashable {
    public var online: Bool
    
    public var revokeTokensIssuedBefore: Date?
    
    public var shadowBanned: Bool
    
    public var custom: [String: RawJSON]
    
    public var lastActive: Date?
    
    public var updatedAt: Date?
    
    public var deactivatedAt: Date?
    
    public var deletedAt: Date?
    
    public var createdAt: Date?
    
    public var id: String
    
    public var language: String?
    
    public var teams: [String]?
    
    public var banExpires: Date?
    
    public var banned: Bool
    
    public var role: String
    
    public var invisible: Bool?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public init(online: Bool, revokeTokensIssuedBefore: Date?, shadowBanned: Bool, custom: [String: RawJSON], lastActive: Date?, updatedAt: Date?, deactivatedAt: Date?, deletedAt: Date?, createdAt: Date?, id: String, language: String?, teams: [String]?, banExpires: Date?, banned: Bool, role: String, invisible: Bool?, pushNotifications: StreamChatPushNotificationSettings?) {
        self.online = online
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.shadowBanned = shadowBanned
        
        self.custom = custom
        
        self.lastActive = lastActive
        
        self.updatedAt = updatedAt
        
        self.deactivatedAt = deactivatedAt
        
        self.deletedAt = deletedAt
        
        self.createdAt = createdAt
        
        self.id = id
        
        self.language = language
        
        self.teams = teams
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.role = role
        
        self.invisible = invisible
        
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case online
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case shadowBanned = "shadow_banned"
        
        case custom = "Custom"
        
        case lastActive = "last_active"
        
        case updatedAt = "updated_at"
        
        case deactivatedAt = "deactivated_at"
        
        case deletedAt = "deleted_at"
        
        case createdAt = "created_at"
        
        case id
        
        case language
        
        case teams
        
        case banExpires = "ban_expires"
        
        case banned
        
        case role
        
        case invisible
        
        case pushNotifications = "push_notifications"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(lastActive, forKey: .lastActive)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
    }
}
