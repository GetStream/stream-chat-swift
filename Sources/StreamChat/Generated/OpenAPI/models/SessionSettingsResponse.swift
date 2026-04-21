//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SessionSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var inactivityTimeoutSeconds: Int

    init(inactivityTimeoutSeconds: Int) {
        self.inactivityTimeoutSeconds = inactivityTimeoutSeconds
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case inactivityTimeoutSeconds = "inactivity_timeout_seconds"
    }

    static func == (lhs: SessionSettingsResponse, rhs: SessionSettingsResponse) -> Bool {
        lhs.inactivityTimeoutSeconds == rhs.inactivityTimeoutSeconds
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(inactivityTimeoutSeconds)
    }
}
