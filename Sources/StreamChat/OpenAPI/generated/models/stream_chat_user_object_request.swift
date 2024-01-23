//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserObjectRequest: Codable, Hashable {
    public var id: String
    
    public var invisible: Bool? = nil
    
    public var language: String? = nil
    
    public var role: String? = nil
    
    public var teams: [String]? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public var pushNotifications: StreamChatPushNotificationSettingsRequest? = nil
    
    public init(id: String, invisible: Bool? = nil, language: String? = nil, role: String? = nil, teams: [String]? = nil, custom: [String: RawJSON]? = nil, pushNotifications: StreamChatPushNotificationSettingsRequest? = nil) {
        self.id = id
        
        self.invisible = invisible
        
        self.language = language
        
        self.role = role
        
        self.teams = teams
        
        self.custom = custom
        
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case invisible
        
        case language
        
        case role
        
        case teams
        
        case custom
        
        case pushNotifications = "push_notifications"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(invisible, forKey: .invisible)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
    }
}
