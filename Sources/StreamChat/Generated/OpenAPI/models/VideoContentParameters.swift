//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VideoContentParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var labelOperator: String?

    init(harmLabels: [String]? = nil, labelOperator: String? = nil) {
        self.harmLabels = harmLabels
        self.labelOperator = labelOperator
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case labelOperator = "label_operator"
    }

    static func == (lhs: VideoContentParameters, rhs: VideoContentParameters) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.labelOperator == rhs.labelOperator
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(labelOperator)
    }
}
