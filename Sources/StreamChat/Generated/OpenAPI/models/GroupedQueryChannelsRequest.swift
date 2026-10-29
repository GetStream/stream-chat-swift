//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedQueryChannelsRequest: Sendable, Encodable, JSONEncodable {
    /// Groups to return, keyed by stored group name. Each entry can define limit, next, prev, and optional filter_conditions: date bounds for stored groups; all supports combined group/date branches or one group $ne exclusion. Cursors are only allowed when requesting exactly one group. Omitted or null filters preserve legacy grouping, including all.
    let groups: [String: GroupedChannelsGroupRequest]?
    /// Default max channels per group (default 10)
    let limit: Int?
    /// Whether to subscribe to presence events for channel members
    let presence: Bool?
    /// Optional query_timestamp descending with NULLS LAST when enabled. Omitted sort preserves existing last_updated ordering and cursor formats
    let sort: [SortParamRequest]?
    /// Whether to start watching found channels or not
    let watch: Bool?

    init(
        groups: [String: GroupedChannelsGroupRequest]? = nil,
        limit: Int? = nil,
        presence: Bool? = nil,
        sort: [SortParamRequest]? = nil,
        watch: Bool? = nil
    ) {
        self.groups = groups
        self.limit = limit
        self.presence = presence
        self.sort = sort
        self.watch = watch
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(groups, forKey: .groups)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(presence, forKey: .presence)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encodeIfPresent(watch, forKey: .watch)
    }
}
