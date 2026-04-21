//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AWSRekognitionRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum AWSRekognitionRuleAction: String, Sendable, Codable, CaseIterable {
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

    var action: AWSRekognitionRuleAction
    var label: String
    var minConfidence: Float
    var subclassifications: [String: RawJSON]?

    init(action: AWSRekognitionRuleAction, label: String, minConfidence: Float, subclassifications: [String: RawJSON]? = nil) {
        self.action = action
        self.label = label
        self.minConfidence = minConfidence
        self.subclassifications = subclassifications
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case label
        case minConfidence = "min_confidence"
        case subclassifications
    }

    static func == (lhs: AWSRekognitionRule, rhs: AWSRekognitionRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.label == rhs.label &&
            lhs.minConfidence == rhs.minConfidence &&
            lhs.subclassifications == rhs.subclassifications
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(label)
        hasher.combine(minConfidence)
        hasher.combine(subclassifications)
    }
}
