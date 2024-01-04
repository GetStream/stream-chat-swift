//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var members: [StreamChatMemberRequest]?
    
    public var settingsOverride: StreamChatCallSettingsRequest?
    
    public var startsAt: String?
    
    public var team: String?
    
    public init(custom: [String: RawJSON]?, members: [StreamChatMemberRequest]?, settingsOverride: StreamChatCallSettingsRequest?, startsAt: String?, team: String?) {
        self.custom = custom
        
        self.members = members
        
        self.settingsOverride = settingsOverride
        
        self.startsAt = startsAt
        
        self.team = team
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case members
        
        case settingsOverride = "settings_override"
        
        case startsAt = "starts_at"
        
        case team
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(settingsOverride, forKey: .settingsOverride)
        
        try container.encode(startsAt, forKey: .startsAt)
        
        try container.encode(team, forKey: .team)
    }
}
