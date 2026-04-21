//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagCountRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var threshold: Int?

    init(threshold: Int? = nil) {
        self.threshold = threshold
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case threshold
    }

    static func == (lhs: FlagCountRuleParameters, rhs: FlagCountRuleParameters) -> Bool {
        lhs.threshold == rhs.threshold
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(threshold)
    }
}
