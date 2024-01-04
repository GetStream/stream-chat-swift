//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObjectRequest: Codable, Hashable {
    public var invisible: Bool?
    
    public var language: String?
    
    public var pushNotifications: StreamChatPushNotificationSettingsRequest?
    
    public var role: String?
    
    public var teams: [String]?
    
    public var custom: [String: RawJSON]?
    
    public var id: String
    
    public init(invisible: Bool?, language: String?, pushNotifications: StreamChatPushNotificationSettingsRequest?, role: String?, teams: [String]?, custom: [String: RawJSON]?, id: String) {
        self.invisible = invisible
        
        self.language = language
        
        self.pushNotifications = pushNotifications
        
        self.role = role
        
        self.teams = teams
        
        self.custom = custom
        
        self.id = id
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case invisible
        
        case language
        
        case pushNotifications = "push_notifications"
        
        case role
        
        case teams
        
        case custom = "Custom"
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
    }
}
