//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryPollsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter to apply to the query
    var filter: [String: RawJSON]?
    var limit: Int?
    var next: String?
    var prev: String?
    /// [RawJSON] of sort parameters
    var sort: [SortParamRequestOpenAPI]?

    init(filter: [String: RawJSON]? = nil, limit: Int? = nil, next: String? = nil, prev: String? = nil, sort: [SortParamRequestOpenAPI]? = nil) {
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

    static func == (lhs: QueryPollsRequest, rhs: QueryPollsRequest) -> Bool {
        lhs.filter == rhs.filter &&
            lhs.limit == rhs.limit &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.sort == rhs.sort
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filter)
        hasher.combine(limit)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(sort)
    }
}
