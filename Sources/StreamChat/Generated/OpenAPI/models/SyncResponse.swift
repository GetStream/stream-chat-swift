//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SyncResponse: Sendable, Decodable {
    /// List of events
    let events: [EventPayload]
    /// List of CIDs that user can't access
    let inaccessibleCids: [String]?

    init(events: [EventPayload], inaccessibleCids: [String]? = nil) {
        self.events = events
        self.inaccessibleCids = inaccessibleCids
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case events
        case inaccessibleCids = "inaccessible_cids"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        events = try container.decodeArrayIgnoringFailures([EventPayload].self, forKey: .events)
        inaccessibleCids = try container.decodeIfPresent([String].self, forKey: .inaccessibleCids)
    }
}
