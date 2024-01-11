//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObjectRequest: Codable, Hashable {
    public var id: String
    
    public var teams: [String]?
    
    public var pushNotifications: StreamChatPushNotificationSettingsRequest?
    
    public var revokeTokensIssuedBefore: String?
    
    public var role: String?
    
    public var custom: [String: RawJSON]?
    
    public var banExpires: String?
    
    public var banned: Bool?
    
    public var invisible: Bool?
    
    public var language: String?
    
    public init(id: String, teams: [String]?, pushNotifications: StreamChatPushNotificationSettingsRequest?, revokeTokensIssuedBefore: String?, role: String?, custom: [String: RawJSON]?, banExpires: String?, banned: Bool?, invisible: Bool?, language: String?) {
        self.id = id
        
        self.teams = teams
        
        self.pushNotifications = pushNotifications
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.role = role
        
        self.custom = custom
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.invisible = invisible
        
        self.language = language
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case teams
        
        case pushNotifications = "push_notifications"
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case role
        
        case custom
        
        case banExpires = "ban_expires"
        
        case banned
        
        case invisible
        
        case language
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(language, forKey: .language)
    }
}
