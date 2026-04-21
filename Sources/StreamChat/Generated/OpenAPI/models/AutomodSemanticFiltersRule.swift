//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AutomodSemanticFiltersRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum AutomodSemanticFiltersRuleAction: String, Sendable, Codable, CaseIterable {
        case bounce
        case bounceFlag = "bounce_flag"
        case bounceRemove = "bounce_remove"
        case flag
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

    var action: AutomodSemanticFiltersRuleAction
    var name: String
    var threshold: Float

    init(action: AutomodSemanticFiltersRuleAction, name: String, threshold: Float) {
        self.action = action
        self.name = name
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case name
        case threshold
    }

    static func == (lhs: AutomodSemanticFiltersRule, rhs: AutomodSemanticFiltersRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.name == rhs.name &&
            lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(name)
        hasher.combine(threshold)
    }
}
