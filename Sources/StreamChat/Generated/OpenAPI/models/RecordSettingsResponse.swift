//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RecordSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var audioOnly: Bool
    var layout: LayoutSettingsResponse
    var mode: String
    var quality: String

    init(audioOnly: Bool, layout: LayoutSettingsResponse, mode: String, quality: String) {
        self.audioOnly = audioOnly
        self.layout = layout
        self.mode = mode
        self.quality = quality
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        case layout
        case mode
        case quality
    }

    static func == (lhs: RecordSettingsResponse, rhs: RecordSettingsResponse) -> Bool {
        lhs.audioOnly == rhs.audioOnly &&
            lhs.layout == rhs.layout &&
            lhs.mode == rhs.mode &&
            lhs.quality == rhs.quality
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(audioOnly)
        hasher.combine(layout)
        hasher.combine(mode)
        hasher.combine(quality)
    }
}
