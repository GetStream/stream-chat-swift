//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelMessageCountRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var `operator`: String?
    var threshold: Int?

    init(operator: String? = nil, threshold: Int? = nil) {
        self.operator = `operator`
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case `operator`
        case threshold
    }

    static func == (lhs: ChannelMessageCountRuleParameters, rhs: ChannelMessageCountRuleParameters) -> Bool {
        lhs.operator == rhs.operator &&
            lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(`operator`)
        hasher.combine(threshold)
    }
}
