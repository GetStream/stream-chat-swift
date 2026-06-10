//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdatePollPartialRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Sets new field values
    var set: [String: RawJSON]?
    /// Array of field names to unset
    var unset: [String]?

    init(set: [String: RawJSON]? = nil, unset: [String]? = nil) {
        self.set = set
        self.unset = unset
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        case unset
    }

    static func == (lhs: UpdatePollPartialRequest, rhs: UpdatePollPartialRequest) -> Bool {
        lhs.set == rhs.set &&
            lhs.unset == rhs.unset
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(set)
        hasher.combine(unset)
    }
}
