//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsGroupRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var limit: Int?
    var next: String?
    var prev: String?

    init(limit: Int? = nil, next: String? = nil, prev: String? = nil) {
        self.limit = limit
        self.next = next
        self.prev = prev
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case next
        case prev
    }

    static func == (lhs: GroupedChannelsGroupRequest, rhs: GroupedChannelsGroupRequest) -> Bool {
        lhs.limit == rhs.limit &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(limit)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
