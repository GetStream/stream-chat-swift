//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SyncResponse: Sendable, Decodable {
    /// List of events
    let events: [WSEvent]

    init(events: [WSEvent]) {
        self.events = events
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        events = try container.decodeArrayIgnoringFailures([WSEvent].self, forKey: .events)
    }
}
