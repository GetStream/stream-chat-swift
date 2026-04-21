//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EventResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var event: WSEvent

    init(duration: String, event: WSEvent) {
        self.duration = duration
        self.event = event
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case event
    }

    static func == (lhs: EventResponse, rhs: EventResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.event == rhs.event
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(event)
    }
}
