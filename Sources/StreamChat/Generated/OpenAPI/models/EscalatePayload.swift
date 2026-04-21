//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EscalatePayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Additional context for the reviewer
    var notes: String?
    /// Priority of the escalation (low, medium, high)
    var priority: String?
    /// Reason for the escalation (from configured escalation_reasons)
    var reason: String?

    init(notes: String? = nil, priority: String? = nil, reason: String? = nil) {
        self.notes = notes
        self.priority = priority
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case notes
        case priority
        case reason
    }

    static func == (lhs: EscalatePayload, rhs: EscalatePayload) -> Bool {
        lhs.notes == rhs.notes &&
            lhs.priority == rhs.priority &&
            lhs.reason == rhs.reason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(notes)
        hasher.combine(priority)
        hasher.combine(reason)
    }
}
