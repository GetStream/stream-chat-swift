//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case poll
        case type
    }
}
