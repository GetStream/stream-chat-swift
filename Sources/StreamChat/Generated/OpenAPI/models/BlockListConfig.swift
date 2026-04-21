//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockListConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var async: Bool?
    var enabled: Bool
    var matchSubstring: Bool?
    var rules: [BlockListRule]

    init(async: Bool? = nil, enabled: Bool, matchSubstring: Bool? = nil, rules: [BlockListRule]) {
        self.async = async
        self.enabled = enabled
        self.matchSubstring = matchSubstring
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case async
        case enabled
        case matchSubstring = "match_substring"
        case rules
    }

    static func == (lhs: BlockListConfig, rhs: BlockListConfig) -> Bool {
        lhs.async == rhs.async &&
            lhs.enabled == rhs.enabled &&
            lhs.matchSubstring == rhs.matchSubstring &&
            lhs.rules == rhs.rules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(async)
        hasher.combine(enabled)
        hasher.combine(matchSubstring)
        hasher.combine(rules)
    }
}
