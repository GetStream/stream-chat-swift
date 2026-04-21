//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIImageConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var async: Bool?
    var enabled: Bool
    var ocrRules: [OCRRule]
    var rules: [AWSRekognitionRule]

    init(async: Bool? = nil, enabled: Bool, ocrRules: [OCRRule], rules: [AWSRekognitionRule]) {
        self.async = async
        self.enabled = enabled
        self.ocrRules = ocrRules
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case async
        case enabled
        case ocrRules = "ocr_rules"
        case rules
    }

    static func == (lhs: AIImageConfig, rhs: AIImageConfig) -> Bool {
        lhs.async == rhs.async &&
            lhs.enabled == rhs.enabled &&
            lhs.ocrRules == rhs.ocrRules &&
            lhs.rules == rhs.rules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(async)
        hasher.combine(enabled)
        hasher.combine(ocrRules)
        hasher.combine(rules)
    }
}
