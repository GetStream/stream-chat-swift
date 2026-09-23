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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case offset
    }
}
