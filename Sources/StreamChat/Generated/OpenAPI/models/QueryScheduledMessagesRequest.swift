//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryScheduledMessagesRequest: Sendable, Encodable, JSONEncodable {
    /// Filter for querying scheduled messages
    let filter: ScheduledMessagesFilter?
    /// Page size, 1 to 100. Defaults to 20
    let limit: Int?
    /// Cursor from the previous page
    let next: String?
    /// Only scheduled_at ascending is supported. Pending messages come before failed ones
    let sort: [SortParamRequest]?

    init(
        filter: ScheduledMessagesFilter? = nil,
        limit: Int? = nil,
        next: String? = nil,
        sort: [SortParamRequest]? = nil
    ) {
        self.filter = filter
        self.limit = limit
        self.next = next
        self.sort = sort
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(filter, forKey: .filter)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(sort, forKey: .sort)
    }
}
