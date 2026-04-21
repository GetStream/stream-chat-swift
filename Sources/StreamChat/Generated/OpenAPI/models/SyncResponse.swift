//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SyncResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// List of events
    var events: [WSEvent]
    /// List of CIDs that user can't access
    var inaccessibleCids: [String]?

    init(duration: String, events: [WSEvent], inaccessibleCids: [String]? = nil) {
        self.duration = duration
        self.events = events
        self.inaccessibleCids = inaccessibleCids
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case events
        case inaccessibleCids = "inaccessible_cids"
    }

    static func == (lhs: SyncResponse, rhs: SyncResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.events == rhs.events &&
            lhs.inaccessibleCids == rhs.inaccessibleCids
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(events)
        hasher.combine(inaccessibleCids)
    }
}
