//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SortParamRequestModel: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Direction of sorting, 1 for Ascending, -1 for Descending, default is 1. One of: -1, 1
    var direction: Int?
    /// Name of field to sort by
    var field: String?
    /// Type of field to sort by. Empty string or omitted means string type (default). One of: number, boolean
    var type: String?

    init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
        case type
    }

    static func == (lhs: SortParamRequestModel, rhs: SortParamRequestModel) -> Bool {
        lhs.direction == rhs.direction &&
            lhs.field == rhs.field &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(direction)
        hasher.combine(field)
        hasher.combine(type)
    }
}
