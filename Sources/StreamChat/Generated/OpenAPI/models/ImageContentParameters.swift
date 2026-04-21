//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageContentParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var labelOperator: String?
    var minConfidence: Float?

    init(harmLabels: [String]? = nil, labelOperator: String? = nil, minConfidence: Float? = nil) {
        self.harmLabels = harmLabels
        self.labelOperator = labelOperator
        self.minConfidence = minConfidence
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case labelOperator = "label_operator"
        case minConfidence = "min_confidence"
    }

    static func == (lhs: ImageContentParameters, rhs: ImageContentParameters) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.labelOperator == rhs.labelOperator &&
            lhs.minConfidence == rhs.minConfidence
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(labelOperator)
        hasher.combine(minConfidence)
    }
}
