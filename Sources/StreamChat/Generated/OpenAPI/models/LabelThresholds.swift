//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class LabelThresholds: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Threshold for automatic message block
    var block: Float?
    /// Threshold for automatic message flag
    var flag: Float?

    init(block: Float? = nil, flag: Float? = nil) {
        self.block = block
        self.flag = flag
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case block
        case flag
    }

    static func == (lhs: LabelThresholds, rhs: LabelThresholds) -> Bool {
        lhs.block == rhs.block &&
            lhs.flag == rhs.flag
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(block)
        hasher.combine(flag)
    }
}
