//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PaginationParams: Sendable, Encodable, JSONEncodable {
    let limit: Int?
    let offset: Int?

    init(limit: Int? = nil, offset: Int? = nil) {
        self.limit = limit
        self.offset = offset
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(offset, forKey: .offset)
    }
}
