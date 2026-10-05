//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollDeletedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let poll: PollPayload
    /// The type of event: "poll.deleted" in this case
    let type: String

    init(createdAt: Date, poll: PollPayload, type: String = "poll.deleted") {
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
