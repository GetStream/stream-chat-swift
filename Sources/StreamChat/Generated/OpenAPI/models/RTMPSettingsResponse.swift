//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RTMPSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var enabled: Bool
    var layout: LayoutSettingsResponse
    var quality: String

    init(enabled: Bool, layout: LayoutSettingsResponse, quality: String) {
        self.enabled = enabled
        self.layout = layout
        self.quality = quality
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case layout
        case quality
    }

    static func == (lhs: RTMPSettingsResponse, rhs: RTMPSettingsResponse) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.layout == rhs.layout &&
            lhs.quality == rhs.quality
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(layout)
        hasher.combine(quality)
    }
}
