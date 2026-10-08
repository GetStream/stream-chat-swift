//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a poll is closed.
final class PollClosedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let poll: PollPayload
    /// The type of event: "poll.closed" in this case
    let type: String

    init(createdAt: Date, poll: PollPayload, type: String = "poll.closed") {
        self.createdAt = createdAt
        self.poll = poll
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.poll = try container.decode(PollPayload.self, forKey: .poll)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
