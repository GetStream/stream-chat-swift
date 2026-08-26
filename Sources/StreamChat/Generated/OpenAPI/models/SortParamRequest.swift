//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SortParamRequest: Sendable, Codable, JSONEncodable {
    /// Direction of sorting, 1 for Ascending, -1 for Descending, default is 1. One of: -1, 1
    let direction: Int?
    /// Name of field to sort by
    let field: String?
    /// Type of field to sort by. Empty string or omitted means string type (default). One of: number, boolean
    let type: String?

    init(direction: Int? = nil, field: String? = nil, type: String? = nil) {
        self.direction = direction
        self.field = field
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
        case type
    }
}
