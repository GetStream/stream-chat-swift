//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EscalationMetadata: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var notes: String?
    var priority: String?
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

    static func == (lhs: EscalationMetadata, rhs: EscalationMetadata) -> Bool {
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
