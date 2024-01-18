//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObjectRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var banned: Bool?
    
    public var id: String
    
    public var invisible: Bool?
    
    public var revokeTokensIssuedBefore: Date?
    
    public var banExpires: Date?
    
    public var language: String?
    
    public var pushNotifications: StreamChatPushNotificationSettingsRequest?
    
    public var role: String?
    
    public var teams: [String]?
    
    public init(custom: [String: RawJSON]?, banned: Bool?, id: String, invisible: Bool?, revokeTokensIssuedBefore: Date?, banExpires: Date?, language: String?, pushNotifications: StreamChatPushNotificationSettingsRequest?, role: String?, teams: [String]?) {
        self.custom = custom
        
        self.banned = banned
        
        self.id = id
        
        self.invisible = invisible
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.banExpires = banExpires
        
        self.language = language
        
        self.pushNotifications = pushNotifications
        
        self.role = role
        
        self.teams = teams
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom = "Custom"
        
        case banned
        
        case id
        
        case invisible
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case banExpires = "ban_expires"
        
        case language
        
        case pushNotifications = "push_notifications"
        
        case role
        
        case teams
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(teams, forKey: .teams)
    }
}
