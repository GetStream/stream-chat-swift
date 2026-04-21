//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RuleBuilderConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var async: Bool?
    var rules: [RuleBuilderRule]?

    init(async: Bool? = nil, rules: [RuleBuilderRule]? = nil) {
        self.async = async
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case async
        case rules
    }

    static func == (lhs: RuleBuilderConfig, rhs: RuleBuilderConfig) -> Bool {
        lhs.async == rhs.async &&
            lhs.rules == rhs.rules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(async)
        hasher.combine(rules)
    }
}
