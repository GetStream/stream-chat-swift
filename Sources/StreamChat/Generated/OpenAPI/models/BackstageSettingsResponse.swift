//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BackstageSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var enabled: Bool
    var joinAheadTimeSeconds: Int?

    init(enabled: Bool, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
    }

    static func == (lhs: BackstageSettingsResponse, rhs: BackstageSettingsResponse) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(joinAheadTimeSeconds)
    }
}
