//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryReactionsRequest: Sendable, Encodable, JSONEncodable {
    /// Filter to apply to the query
    let filter: (any Encodable & Sendable)?
    let limit: Int?

    init(filter: (any Encodable & Sendable)? = nil, limit: Int? = nil) {
        self.filter = filter
        self.limit = limit
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filter
        case limit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let filter {
            try container.encode(filter, forKey: .filter)
        }
        try container.encodeIfPresent(limit, forKey: .limit)
    }
}
