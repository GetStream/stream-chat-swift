//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AITextConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var async: Bool?
    var enabled: Bool
    var profile: String
    var rules: [BodyguardRule]
    var severityRules: [BodyguardSeverityRule]

    init(async: Bool? = nil, enabled: Bool, profile: String, rules: [BodyguardRule], severityRules: [BodyguardSeverityRule]) {
        self.async = async
        self.enabled = enabled
        self.profile = profile
        self.rules = rules
        self.severityRules = severityRules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case async
        case enabled
        case profile
        case rules
        case severityRules = "severity_rules"
    }

    static func == (lhs: AITextConfig, rhs: AITextConfig) -> Bool {
        lhs.async == rhs.async &&
            lhs.enabled == rhs.enabled &&
            lhs.profile == rhs.profile &&
            lhs.rules == rhs.rules &&
            lhs.severityRules == rhs.severityRules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(async)
        hasher.combine(enabled)
        hasher.combine(profile)
        hasher.combine(rules)
        hasher.combine(severityRules)
    }
}
