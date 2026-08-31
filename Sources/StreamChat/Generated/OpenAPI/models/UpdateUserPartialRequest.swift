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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case set
        case unset
    }
}
