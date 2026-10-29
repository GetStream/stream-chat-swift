//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUserPartialRequest: Sendable, Encodable, JSONEncodable {
    /// User ID to update
    let id: String
    let set: [String: RawJSON]?
    let unset: [String]?

    init(id: String, set: [String: RawJSON]? = nil, unset: [String]? = nil) {
        self.id = id
        self.set = set
        self.unset = unset
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(set, forKey: .set)
        try container.encodeIfPresent(unset, forKey: .unset)
    }
}
