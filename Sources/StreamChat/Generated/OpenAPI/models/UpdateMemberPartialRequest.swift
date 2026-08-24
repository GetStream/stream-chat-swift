//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMemberPartialRequest: Sendable, Encodable, JSONEncodable {
    let set: [String: RawJSON]?
    let unset: [String]?

    init(
        set: [String: RawJSON]? = nil,
        unset: [String]? = nil
    ) {
        self.set = set
        self.unset = unset
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        case unset
    }
}
