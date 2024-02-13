//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct HLSSettings: Codable, Hashable {
    public var autoOn: Bool
    public var enabled: Bool
    public var qualityTracks: [String]
    public var layout: LayoutSettings? = nil

    public init(autoOn: Bool, enabled: Bool, qualityTracks: [String], layout: LayoutSettings? = nil) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.qualityTracks = qualityTracks
        self.layout = layout
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        case enabled
        case qualityTracks = "quality_tracks"
        case layout
    }
}
