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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case next
        case prev
    }
}
