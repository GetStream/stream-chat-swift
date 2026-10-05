//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteRemovedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let poll: PollPayload
    let pollVote: PollVotePayload
    /// The type of event: "poll.vote_removed" in this case
    let type: String

    init(
        createdAt: Date,
        poll: PollPayload,
        pollVote: PollVotePayload,
        type: String = "poll.vote_removed"
    ) {
        self.createdAt = createdAt
        self.poll = poll
        self.pollVote = pollVote
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case poll
        case pollVote = "poll_vote"
        case type
    }
}
