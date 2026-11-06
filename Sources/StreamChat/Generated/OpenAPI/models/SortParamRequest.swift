//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SortParamRequest: Sendable, Codable, JSONEncodable {
    /// Direction of sorting, 1 for Ascending, -1 for Descending, default is 1. One of: -1, 1
    let direction: Int?
    /// Name of field to sort by
    let field: String?

    init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.direction = try container.decodeIfPresent(Int.self, forKey: .direction)
        self.field = try container.decodeIfPresent(String.self, forKey: .field)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(direction, forKey: .direction)
        try container.encodeIfPresent(field, forKey: .field)
    }
}
