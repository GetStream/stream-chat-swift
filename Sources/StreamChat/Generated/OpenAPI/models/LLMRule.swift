//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class LLMRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum LLMRuleAction: String, Sendable, Codable, CaseIterable {
        case bounce
        case bounceFlag = "bounce_flag"
        case bounceRemove = "bounce_remove"
        case flag
        case keep
        case remove
        case shadow
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var action: LLMRuleAction
    var description: String
    var label: String
    var severityRules: [BodyguardSeverityRule]

    init(action: LLMRuleAction, description: String, label: String, severityRules: [BodyguardSeverityRule]) {
        self.action = action
        self.description = description
        self.label = label
        self.severityRules = severityRules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case description
        case label
        case severityRules = "severity_rules"
    }

    static func == (lhs: LLMRule, rhs: LLMRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.description == rhs.description &&
            lhs.label == rhs.label &&
            lhs.severityRules == rhs.severityRules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(description)
        hasher.combine(label)
        hasher.combine(severityRules)
    }
}
