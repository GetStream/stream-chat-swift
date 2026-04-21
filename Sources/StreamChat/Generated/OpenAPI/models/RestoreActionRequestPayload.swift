//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RestoreActionRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Reason for the appeal decision
    var decisionReason: String?

    init(decisionReason: String? = nil) {
        self.decisionReason = decisionReason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case decisionReason = "decision_reason"
    }

    static func == (lhs: RestoreActionRequestPayload, rhs: RestoreActionRequestPayload) -> Bool {
        lhs.decisionReason == rhs.decisionReason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(decisionReason)
    }
}
