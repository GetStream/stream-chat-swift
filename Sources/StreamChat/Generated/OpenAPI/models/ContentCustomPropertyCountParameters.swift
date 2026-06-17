//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ContentCustomPropertyCountParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var `operator`: String?
    var propertyKey: String?
    var threshold: Int?
    var timeWindow: String?

    init(operator: String? = nil, propertyKey: String? = nil, threshold: Int? = nil, timeWindow: String? = nil) {
        self.operator = `operator`
        self.propertyKey = propertyKey
        self.threshold = threshold
        self.timeWindow = timeWindow
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case `operator`
        case propertyKey = "property_key"
        case threshold
        case timeWindow = "time_window"
    }

    static func == (lhs: ContentCustomPropertyCountParameters, rhs: ContentCustomPropertyCountParameters) -> Bool {
        lhs.operator == rhs.operator &&
            lhs.propertyKey == rhs.propertyKey &&
            lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(`operator`)
        hasher.combine(propertyKey)
        hasher.combine(threshold)
        hasher.combine(timeWindow)
    }
}
