//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RejectAppealRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Reason for rejecting the appeal
    var decisionReason: String

    init(decisionReason: String) {
        self.decisionReason = decisionReason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case decisionReason = "decision_reason"
    }

    static func == (lhs: RejectAppealRequestPayload, rhs: RejectAppealRequestPayload) -> Bool {
        lhs.decisionReason == rhs.decisionReason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(decisionReason)
    }
}
