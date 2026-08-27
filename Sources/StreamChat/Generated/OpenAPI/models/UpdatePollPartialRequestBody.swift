//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class UpdatePollPartialRequestBody: Sendable, Encodable, JSONEncodable {
    /// Sets new field values
    let set: [String: RawJSON]?
    /// Array of field names to unset
    let unset: [String]?

    init(set: [String: RawJSON]? = nil, unset: [String]? = nil) {
        self.set = set
        self.unset = unset
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        case unset
    }
}
