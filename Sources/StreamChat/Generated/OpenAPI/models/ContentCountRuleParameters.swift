//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ContentCountRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var threshold: Int?
    var timeWindow: String?

    init(threshold: Int? = nil, timeWindow: String? = nil) {
        self.threshold = threshold
        self.timeWindow = timeWindow
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case threshold
        case timeWindow = "time_window"
    }

    static func == (lhs: ContentCountRuleParameters, rhs: ContentCountRuleParameters) -> Bool {
        lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(threshold)
        hasher.combine(timeWindow)
    }
}
