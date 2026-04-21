//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VideoRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var harmLabels: [String]?
    var threshold: Int?
    var timeWindow: String?

    init(harmLabels: [String]? = nil, threshold: Int? = nil, timeWindow: String? = nil) {
        self.harmLabels = harmLabels
        self.threshold = threshold
        self.timeWindow = timeWindow
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case harmLabels = "harm_labels"
        case threshold
        case timeWindow = "time_window"
    }

    static func == (lhs: VideoRuleParameters, rhs: VideoRuleParameters) -> Bool {
        lhs.harmLabels == rhs.harmLabels &&
            lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(harmLabels)
        hasher.combine(threshold)
        hasher.combine(timeWindow)
    }
}
