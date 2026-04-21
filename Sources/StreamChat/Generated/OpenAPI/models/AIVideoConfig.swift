//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIVideoConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var async: Bool?
    var enabled: Bool
    var rules: [AWSRekognitionRule]

    init(async: Bool? = nil, enabled: Bool, rules: [AWSRekognitionRule]) {
        self.async = async
        self.enabled = enabled
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case async
        case enabled
        case rules
    }

    static func == (lhs: AIVideoConfig, rhs: AIVideoConfig) -> Bool {
        lhs.async == rhs.async &&
            lhs.enabled == rhs.enabled &&
            lhs.rules == rhs.rules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(async)
        hasher.combine(enabled)
        hasher.combine(rules)
    }
}
