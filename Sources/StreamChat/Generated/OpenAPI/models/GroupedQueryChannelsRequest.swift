//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedQueryChannelsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Groups to return, keyed by group name. Each group can define limit, next, or prev. 'next' and 'prev' cursors are only allowed when the request contains exactly one group; multi-group pagination is rejected.
    var groups: [String: GroupedChannelsGroupRequest]?
    /// Default max channels per group (default 10)
    var limit: Int?
    /// Whether to subscribe to presence events for channel members
    var presence: Bool?
    /// Whether to start watching found channels or not
    var watch: Bool?

    init(groups: [String: GroupedChannelsGroupRequest]? = nil, limit: Int? = nil, presence: Bool? = nil, watch: Bool? = nil) {
        self.groups = groups
        self.limit = limit
        self.presence = presence
        self.watch = watch
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case groups
        case limit
        case presence
        case watch
    }

    static func == (lhs: GroupedQueryChannelsRequest, rhs: GroupedQueryChannelsRequest) -> Bool {
        lhs.groups == rhs.groups &&
            lhs.limit == rhs.limit &&
            lhs.presence == rhs.presence &&
            lhs.watch == rhs.watch
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(groups)
        hasher.combine(limit)
        hasher.combine(presence)
        hasher.combine(watch)
    }
}
