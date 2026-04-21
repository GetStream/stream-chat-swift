//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class OCRRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum OCRRuleAction: String, Sendable, Codable, CaseIterable {
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

    var action: OCRRuleAction
    var label: String

    init(action: OCRRuleAction, label: String) {
        self.action = action
        self.label = label
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case label
    }

    static func == (lhs: OCRRule, rhs: OCRRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.label == rhs.label
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(label)
    }
}
