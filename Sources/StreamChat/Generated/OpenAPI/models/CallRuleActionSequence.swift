//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallRuleActionSequence: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var actions: [String]?
    var callOptions: CallActionOptions?
    var violationNumber: Int?

    init(actions: [String]? = nil, callOptions: CallActionOptions? = nil, violationNumber: Int? = nil) {
        self.actions = actions
        self.callOptions = callOptions
        self.violationNumber = violationNumber
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actions
        case callOptions = "call_options"
        case violationNumber = "violation_number"
    }

    static func == (lhs: CallRuleActionSequence, rhs: CallRuleActionSequence) -> Bool {
        lhs.actions == rhs.actions &&
            lhs.callOptions == rhs.callOptions &&
            lhs.violationNumber == rhs.violationNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actions)
        hasher.combine(callOptions)
        hasher.combine(violationNumber)
    }
}
