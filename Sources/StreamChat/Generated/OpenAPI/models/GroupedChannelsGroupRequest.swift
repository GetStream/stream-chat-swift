//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsGroupRequest: Sendable, Encodable, JSONEncodable {
    let limit: Int?
    let next: String?

    init(limit: Int? = nil, next: String? = nil) {
        self.limit = limit
        self.next = next
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case next
    }
}
