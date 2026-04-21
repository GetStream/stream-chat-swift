//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class LLMConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var appContext: String?
    var async: Bool?
    var enabled: Bool
    var rules: [LLMRule]
    var severityDescriptions: [String: String]?

    init(appContext: String? = nil, async: Bool? = nil, enabled: Bool, rules: [LLMRule], severityDescriptions: [String: String]? = nil) {
        self.appContext = appContext
        self.async = async
        self.enabled = enabled
        self.rules = rules
        self.severityDescriptions = severityDescriptions
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appContext = "app_context"
        case async
        case enabled
        case rules
        case severityDescriptions = "severity_descriptions"
    }

    static func == (lhs: LLMConfig, rhs: LLMConfig) -> Bool {
        lhs.appContext == rhs.appContext &&
            lhs.async == rhs.async &&
            lhs.enabled == rhs.enabled &&
            lhs.rules == rhs.rules &&
            lhs.severityDescriptions == rhs.severityDescriptions
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appContext)
        hasher.combine(async)
        hasher.combine(enabled)
        hasher.combine(rules)
        hasher.combine(severityDescriptions)
    }
}
