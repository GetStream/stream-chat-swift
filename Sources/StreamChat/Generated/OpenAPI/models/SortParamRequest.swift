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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.direction = try container.decodeIfPresent(Int.self, forKey: .direction)
        self.field = try container.decodeIfPresent(String.self, forKey: .field)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(direction, forKey: .direction)
        try container.encodeIfPresent(field, forKey: .field)
        try container.encodeIfPresent(type, forKey: .type)
    }
}
