//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FrameRecordingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var captureIntervalInSeconds: Int
    var mode: String
    var quality: String?

    init(captureIntervalInSeconds: Int, mode: String, quality: String? = nil) {
        self.captureIntervalInSeconds = captureIntervalInSeconds
        self.mode = mode
        self.quality = quality
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case captureIntervalInSeconds = "capture_interval_in_seconds"
        case mode
        case quality
    }

    static func == (lhs: FrameRecordingSettingsResponse, rhs: FrameRecordingSettingsResponse) -> Bool {
        lhs.captureIntervalInSeconds == rhs.captureIntervalInSeconds &&
            lhs.mode == rhs.mode &&
            lhs.quality == rhs.quality
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(captureIntervalInSeconds)
        hasher.combine(mode)
        hasher.combine(quality)
    }
}
