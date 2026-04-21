//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AutomodRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum AutomodRuleAction: String, Sendable, Codable, CaseIterable {
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

    var action: AutomodRuleAction
    var label: String
    var threshold: Float

    init(action: AutomodRuleAction, label: String, threshold: Float) {
        self.action = action
        self.label = label
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case label
        case threshold
    }

    static func == (lhs: AutomodRule, rhs: AutomodRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.label == rhs.label &&
            lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(label)
        hasher.combine(threshold)
    }
}
