//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var autoCancelTimeoutMs: Int
    var incomingCallTimeoutMs: Int
    var missedCallTimeoutMs: Int

    init(autoCancelTimeoutMs: Int, incomingCallTimeoutMs: Int, missedCallTimeoutMs: Int) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
        self.missedCallTimeoutMs = missedCallTimeoutMs
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case autoCancelTimeoutMs = "auto_cancel_timeout_ms"
        case incomingCallTimeoutMs = "incoming_call_timeout_ms"
        case missedCallTimeoutMs = "missed_call_timeout_ms"
    }

    static func == (lhs: RingSettingsResponse, rhs: RingSettingsResponse) -> Bool {
        lhs.autoCancelTimeoutMs == rhs.autoCancelTimeoutMs &&
            lhs.incomingCallTimeoutMs == rhs.incomingCallTimeoutMs &&
            lhs.missedCallTimeoutMs == rhs.missedCallTimeoutMs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(autoCancelTimeoutMs)
        hasher.combine(incomingCallTimeoutMs)
        hasher.combine(missedCallTimeoutMs)
    }
}
