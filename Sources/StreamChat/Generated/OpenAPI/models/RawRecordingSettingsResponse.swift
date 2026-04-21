//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RawRecordingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var mode: String

    init(mode: String) {
        self.mode = mode
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
    }

    static func == (lhs: RawRecordingSettingsResponse, rhs: RawRecordingSettingsResponse) -> Bool {
        lhs.mode == rhs.mode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
