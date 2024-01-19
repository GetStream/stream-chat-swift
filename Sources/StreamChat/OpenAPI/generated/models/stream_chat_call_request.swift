//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRequest: Codable, Hashable {
    public var members: [StreamChatMemberRequest]?
    
    public var settingsOverride: StreamChatCallSettingsRequest?
    
    public var startsAt: Date?
    
    public var team: String?
    
    public var custom: [String: RawJSON]?
    
    public init(members: [StreamChatMemberRequest]?, settingsOverride: StreamChatCallSettingsRequest?, startsAt: Date?, team: String?, custom: [String: RawJSON]?) {
        self.members = members
        
        self.settingsOverride = settingsOverride
        
        self.startsAt = startsAt
        
        self.team = team
        
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case members
        
        case settingsOverride = "settings_override"
        
        case startsAt = "starts_at"
        
        case team
        
        case custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(settingsOverride, forKey: .settingsOverride)
        
        try container.encode(startsAt, forKey: .startsAt)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(custom, forKey: .custom)
    }
}
