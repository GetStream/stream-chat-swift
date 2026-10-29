//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMemberPartialRequest: Sendable, Encodable, JSONEncodable {
    let set: [String: RawJSON]?
    let unset: [String]?

    init(set: [String: RawJSON]? = nil, unset: [String]? = nil) {
        self.set = set
        self.unset = unset
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(set, forKey: .set)
        try container.encodeIfPresent(unset, forKey: .unset)
    }
}
