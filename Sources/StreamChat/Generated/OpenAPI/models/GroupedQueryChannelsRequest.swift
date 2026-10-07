//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedQueryChannelsRequest: Sendable, Encodable, JSONEncodable {
    /// Groups to return, keyed by group name. Each group can define limit, next, or prev. 'next' and 'prev' cursors are only allowed when the request contains exactly one group; multi-group pagination is rejected.
    let groups: [String: GroupedChannelsGroupRequest]?
    /// Default max channels per group (default 10)
    let limit: Int?
    /// Whether to subscribe to presence events for channel members
    let presence: Bool?
    /// Whether to start watching found channels or not
    let watch: Bool?

    init(
        groups: [String: GroupedChannelsGroupRequest]? = nil,
        limit: Int? = nil,
        presence: Bool? = nil,
        watch: Bool? = nil
    ) {
        self.groups = groups
        self.limit = limit
        self.presence = presence
        self.watch = watch
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(groups, forKey: .groups)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(presence, forKey: .presence)
        try container.encodeIfPresent(watch, forKey: .watch)
    }
}
