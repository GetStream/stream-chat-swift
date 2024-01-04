//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateCallRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var settingsOverride: StreamChatCallSettingsRequest?
    
    public var startsAt: String?
    
    public init(custom: [String: RawJSON]?, settingsOverride: StreamChatCallSettingsRequest?, startsAt: String?) {
        self.custom = custom
        
        self.settingsOverride = settingsOverride
        
        self.startsAt = startsAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case settingsOverride = "settings_override"
        
        case startsAt = "starts_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(settingsOverride, forKey: .settingsOverride)
        
        try container.encode(startsAt, forKey: .startsAt)
    }
}
