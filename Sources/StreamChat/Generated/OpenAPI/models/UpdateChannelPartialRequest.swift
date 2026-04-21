//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelPartialRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var set: [String: RawJSON]?
    var unset: [String]?

    init(set: [String: RawJSON]? = nil, unset: [String]? = nil) {
        self.set = set
        self.unset = unset
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        case unset
    }

    static func == (lhs: UpdateChannelPartialRequest, rhs: UpdateChannelPartialRequest) -> Bool {
        lhs.set == rhs.set &&
            lhs.unset == rhs.unset
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(set)
        hasher.combine(unset)
    }
}
