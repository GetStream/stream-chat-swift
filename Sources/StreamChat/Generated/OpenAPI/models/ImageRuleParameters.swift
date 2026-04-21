//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var minConfidence: Float?
    var threshold: Int?
    var timeWindow: String?

    init(harmLabels: [String]? = nil, minConfidence: Float? = nil, threshold: Int? = nil, timeWindow: String? = nil) {
        self.harmLabels = harmLabels
        self.minConfidence = minConfidence
        self.threshold = threshold
        self.timeWindow = timeWindow
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case minConfidence = "min_confidence"
        case threshold
        case timeWindow = "time_window"
    }

    static func == (lhs: ImageRuleParameters, rhs: ImageRuleParameters) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.minConfidence == rhs.minConfidence &&
            lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(minConfidence)
        hasher.combine(threshold)
        hasher.combine(timeWindow)
    }
}
