//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUserPartialRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// User ID to update
    var id: String
    var set: [String: RawJSON]?
    var unset: [String]?

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

    static func == (lhs: UpdateUserPartialRequest, rhs: UpdateUserPartialRequest) -> Bool {
        lhs.id == rhs.id &&
            lhs.set == rhs.set &&
            lhs.unset == rhs.unset
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(set)
        hasher.combine(unset)
    }
}
