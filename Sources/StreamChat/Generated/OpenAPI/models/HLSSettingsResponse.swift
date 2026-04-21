//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HLSSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var autoOn: Bool
    var enabled: Bool
    var layout: LayoutSettingsResponse
    var qualityTracks: [String]

    init(autoOn: Bool, enabled: Bool, layout: LayoutSettingsResponse, qualityTracks: [String]) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.layout = layout
        self.qualityTracks = qualityTracks
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        case enabled
        case layout
        case qualityTracks = "quality_tracks"
    }

    static func == (lhs: HLSSettingsResponse, rhs: HLSSettingsResponse) -> Bool {
        lhs.autoOn == rhs.autoOn &&
            lhs.enabled == rhs.enabled &&
            lhs.layout == rhs.layout &&
            lhs.qualityTracks == rhs.qualityTracks
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(autoOn)
        hasher.combine(enabled)
        hasher.combine(layout)
        hasher.combine(qualityTracks)
    }
}
