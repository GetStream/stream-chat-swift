//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FloodConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var identical: FloodIdenticalConfig?
    var similar: FloodSimilarConfig?

    init(identical: FloodIdenticalConfig? = nil, similar: FloodSimilarConfig? = nil) {
        self.identical = identical
        self.similar = similar
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case identical
        case similar
    }

    static func == (lhs: FloodConfig, rhs: FloodConfig) -> Bool {
        lhs.identical == rhs.identical &&
            lhs.similar == rhs.similar
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identical)
        hasher.combine(similar)
    }
}
