//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHLSSettings: Codable, Hashable {
    public var enabled: Bool
    
    public var layout: StreamChatLayoutSettings?
    
    public var qualityTracks: [String]
    
    public var autoOn: Bool
    
    public init(enabled: Bool, layout: StreamChatLayoutSettings?, qualityTracks: [String], autoOn: Bool) {
        self.enabled = enabled
        
        self.layout = layout
        
        self.qualityTracks = qualityTracks
        
        self.autoOn = autoOn
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        
        case layout
        
        case qualityTracks = "quality_tracks"
        
        case autoOn = "auto_on"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(layout, forKey: .layout)
        
        try container.encode(qualityTracks, forKey: .qualityTracks)
        
        try container.encode(autoOn, forKey: .autoOn)
    }
}
