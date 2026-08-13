//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryReactionsRequest: Sendable, Encodable, JSONEncodable {
    /// Filter to apply to the query
    let filter: (any Encodable & Sendable)?
    let limit: Int?
    let next: String?
    let prev: String?
    /// Array of sort parameters
    let sort: [SortParamRequest]?

    init(
        filter: (any Encodable & Sendable)? = nil,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest]? = nil
    ) {
        self.filter = filter
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filter
        case limit
        case next
        case prev
        case sort
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let filter {
            try container.encode(
                filter,
                forKey: .filter
            )
        }
        try container.encodeIfPresent(
            limit,
            forKey: .limit
        )
        try container.encodeIfPresent(
            next,
            forKey: .next
        )
        try container.encodeIfPresent(
            prev,
            forKey: .prev
        )
        try container.encodeIfPresent(
            sort,
            forKey: .sort
        )
    }
}
