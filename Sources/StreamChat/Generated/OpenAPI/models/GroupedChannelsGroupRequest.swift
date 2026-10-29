//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsGroupRequest: Sendable, Encodable, JSONEncodable {
    /// Optional query_timestamp $gte bound for a stored group, requiring query_timestamp sort; do not repeat its group name. For all, combine group equality/$in and date bounds with $or, or use one standalone group $ne exclusion. An empty object matches a stored group; omitted or null preserves legacy grouping.
    let filterConditions: (any Encodable & Sendable)?
    /// Max channels for this group; omitted or zero uses the request limit
    let limit: Int?
    /// Cursor for the next page; only allowed when requesting one group
    let next: String?
    /// Cursor for the previous page; only allowed when requesting one group
    let prev: String?

    init(
        filterConditions: (any Encodable & Sendable)? = nil,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil
    ) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.next = next
        self.prev = prev
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        if let filterConditions {
            try container.encode(filterConditions, forKey: .filterConditions)
        }
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
    }
}
