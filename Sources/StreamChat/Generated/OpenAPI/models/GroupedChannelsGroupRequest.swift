//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsGroupRequest: Sendable, Encodable, JSONEncodable {
    let limit: Int?
    let next: String?
    let prev: String?

    init(limit: Int? = nil, next: String? = nil, prev: String? = nil) {
        self.limit = limit
        self.next = next
        self.prev = prev
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
    }
}
