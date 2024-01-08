//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHLSSettings: Codable, Hashable {
    public var autoOn: Bool
    
    public var enabled: Bool
    
    public var layout: StreamChatLayoutSettings?
    
    public var qualityTracks: [String]
    
    public init(autoOn: Bool, enabled: Bool, layout: StreamChatLayoutSettings?, qualityTracks: [String]) {
        self.autoOn = autoOn
        
        self.enabled = enabled
        
        self.layout = layout
        
        self.qualityTracks = qualityTracks
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        
        case enabled
        
        case layout
        
        case qualityTracks = "quality_tracks"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoOn, forKey: .autoOn)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(layout, forKey: .layout)
        
        try container.encode(qualityTracks, forKey: .qualityTracks)
    }
}
