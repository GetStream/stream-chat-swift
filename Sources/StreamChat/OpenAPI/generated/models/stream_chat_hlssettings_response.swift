//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHLSSettingsResponse: Codable, Hashable {
    public var qualityTracks: [String]
    
    public var autoOn: Bool
    
    public var enabled: Bool
    
    public init(qualityTracks: [String], autoOn: Bool, enabled: Bool) {
        self.qualityTracks = qualityTracks
        
        self.autoOn = autoOn
        
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case qualityTracks = "quality_tracks"
        
        case autoOn = "auto_on"
        
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(qualityTracks, forKey: .qualityTracks)
        
        try container.encode(autoOn, forKey: .autoOn)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
