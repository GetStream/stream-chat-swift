//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHLSSettingsRequest: Codable, Hashable {
    public var autoOn: Bool?
    
    public var enabled: Bool?
    
    public var qualityTracks: [String]?
    
    public init(autoOn: Bool?, enabled: Bool?, qualityTracks: [String]?) {
        self.autoOn = autoOn
        
        self.enabled = enabled
        
        self.qualityTracks = qualityTracks
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        
        case enabled
        
        case qualityTracks = "quality_tracks"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoOn, forKey: .autoOn)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(qualityTracks, forKey: .qualityTracks)
    }
}
