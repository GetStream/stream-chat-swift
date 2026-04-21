//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PaginationParams: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var limit: Int?
    var offset: Int?

    init(limit: Int? = nil, offset: Int? = nil) {
        self.limit = limit
        self.offset = offset
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case offset
    }

    static func == (lhs: PaginationParams, rhs: PaginationParams) -> Bool {
        lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(limit)
        hasher.combine(offset)
    }
}
