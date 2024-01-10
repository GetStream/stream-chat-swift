//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHLSSettings: Codable, Hashable {
    public var layout: StreamChatLayoutSettings?
    
    public var qualityTracks: [String]
    
    public var autoOn: Bool
    
    public var enabled: Bool
    
    public init(layout: StreamChatLayoutSettings?, qualityTracks: [String], autoOn: Bool, enabled: Bool) {
        self.layout = layout
        
        self.qualityTracks = qualityTracks
        
        self.autoOn = autoOn
        
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case layout
        
        case qualityTracks = "quality_tracks"
        
        case autoOn = "auto_on"
        
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(layout, forKey: .layout)
        
        try container.encode(qualityTracks, forKey: .qualityTracks)
        
        try container.encode(autoOn, forKey: .autoOn)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
