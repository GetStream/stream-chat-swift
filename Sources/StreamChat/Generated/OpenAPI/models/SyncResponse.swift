//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sync response
final class SyncResponse: Sendable, Decodable {
    /// List of events
    let events: [WSEvent]

    init(events: [WSEvent]) {
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.events = try container.decodeArrayIgnoringFailures([WSEvent].self, forKey: .events)
    }
}
