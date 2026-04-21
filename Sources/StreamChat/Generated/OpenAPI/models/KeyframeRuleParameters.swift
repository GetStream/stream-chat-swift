//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class KeyframeRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var minConfidence: Float?
    var threshold: Int?

    init(harmLabels: [String]? = nil, minConfidence: Float? = nil, threshold: Int? = nil) {
        self.harmLabels = harmLabels
        self.minConfidence = minConfidence
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case minConfidence = "min_confidence"
        case threshold
    }

    static func == (lhs: KeyframeRuleParameters, rhs: KeyframeRuleParameters) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.minConfidence == rhs.minConfidence &&
            lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(minConfidence)
        hasher.combine(threshold)
    }
}
