//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a vote on a poll is changed.
final class PollVoteChangedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let poll: PollPayload
    let pollVote: PollVotePayload
    /// The type of event: "poll.vote_changed" in this case
    let type: String

    init(
        createdAt: Date,
        poll: PollPayload,
        pollVote: PollVotePayload,
        type: String = "poll.vote_changed"
    ) {
        self.createdAt = createdAt
        self.poll = poll
        self.pollVote = pollVote
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.poll = try container.decode(PollPayload.self, forKey: .poll)
        self.pollVote = try container.decode(PollVotePayload.self, forKey: .pollVote)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
