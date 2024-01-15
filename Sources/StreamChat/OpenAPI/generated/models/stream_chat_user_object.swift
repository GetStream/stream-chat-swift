//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObject: Codable, Hashable {
    public var updatedAt: Date?
    
    public var createdAt: Date?
    
    public var deactivatedAt: Date?
    
    public var invisible: Bool?
    
    public var online: Bool
    
    public var banExpires: Date?
    
    public var role: String
    
    public var custom: [String: RawJSON]?
    
    public var deletedAt: Date?
    
    public var pushNotifications: StreamChatPushNotificationSettings?
    
    public var teams: [String]?
    
    public var revokeTokensIssuedBefore: String?
    
    public var banned: Bool
    
    public var id: String
    
    public var language: String?
    
    public var lastActive: Date?
    
    public var name: String?
    
    public var imageURL: String?
    
    public init(updatedAt: Date?, createdAt: Date?, deactivatedAt: Date?, invisible: Bool?, online: Bool, banExpires: Date?, role: String, custom: [String: RawJSON], deletedAt: Date?, pushNotifications: StreamChatPushNotificationSettings?, teams: [String]?, revokeTokensIssuedBefore: String?, banned: Bool, id: String, language: String?, lastActive: Date?) {
        self.updatedAt = updatedAt
        
        self.createdAt = createdAt
        
        self.deactivatedAt = deactivatedAt
        
        self.invisible = invisible
        
        self.online = online
        
        self.banExpires = banExpires
        
        self.role = role
        
        self.custom = custom
        
        self.deletedAt = deletedAt
        
        self.pushNotifications = pushNotifications
        
        self.teams = teams
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.banned = banned
        
        self.id = id
        
        self.language = language
        
        self.lastActive = lastActive
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "updated_at"
        
        case createdAt = "created_at"
        
        case deactivatedAt = "deactivated_at"
        
        case invisible
        
        case online
        
        case banExpires = "ban_expires"
        
        case role
        
        case custom
        
        case deletedAt = "deleted_at"
        
        case pushNotifications = "push_notifications"
        
        case teams
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case banned
        
        case id
        
        case language
        
        case lastActive = "last_active"
        
        case imageURL = "image_url"
        
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deactivatedAt, forKey: .deactivatedAt)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(online, forKey: .online)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(lastActive, forKey: .lastActive)
    }
}
