//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FloodIdenticalConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: String
    var enabled: Bool
    var threshold: Int
    var timeWindow: String

    init(action: String, enabled: Bool, threshold: Int, timeWindow: String) {
        self.action = action
        self.enabled = enabled
        self.threshold = threshold
        self.timeWindow = timeWindow
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case enabled
        case threshold
        case timeWindow = "time_window"
    }

    static func == (lhs: FloodIdenticalConfig, rhs: FloodIdenticalConfig) -> Bool {
        lhs.action == rhs.action &&
            lhs.enabled == rhs.enabled &&
            lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(enabled)
        hasher.combine(threshold)
        hasher.combine(timeWindow)
    }
}
