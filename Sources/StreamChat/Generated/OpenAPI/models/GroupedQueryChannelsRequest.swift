//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedQueryChannelsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Max channels per bucket (default 10)
    var limit: Int?
    /// Whether to subscribe to presence events for channel members
    var presence: Bool?
    /// Whether to start watching found channels or not
    var watch: Bool?

    init(limit: Int? = nil, presence: Bool? = nil, watch: Bool? = nil) {
        self.limit = limit
        self.presence = presence
        self.watch = watch
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case presence
        case watch
    }

    static func == (lhs: GroupedQueryChannelsRequest, rhs: GroupedQueryChannelsRequest) -> Bool {
        lhs.limit == rhs.limit &&
            lhs.presence == rhs.presence &&
            lhs.watch == rhs.watch
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(limit)
        hasher.combine(presence)
        hasher.combine(watch)
    }
}
