//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HarmConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var actionSequences: [ActionSequence]
    var cooldownPeriod: Int
    var harmTypes: [String]
    var severity: Int
    var threshold: Int

    init(actionSequences: [ActionSequence], cooldownPeriod: Int, harmTypes: [String], severity: Int, threshold: Int) {
        self.actionSequences = actionSequences
        self.cooldownPeriod = cooldownPeriod
        self.harmTypes = harmTypes
        self.severity = severity
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionSequences = "action_sequences"
        case cooldownPeriod = "cooldown_period"
        case harmTypes = "harm_types"
        case severity
        case threshold
    }

    static func == (lhs: HarmConfig, rhs: HarmConfig) -> Bool {
        lhs.actionSequences == rhs.actionSequences &&
            lhs.cooldownPeriod == rhs.cooldownPeriod &&
            lhs.harmTypes == rhs.harmTypes &&
            lhs.severity == rhs.severity &&
            lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionSequences)
        hasher.combine(cooldownPeriod)
        hasher.combine(harmTypes)
        hasher.combine(severity)
        hasher.combine(threshold)
    }
}
