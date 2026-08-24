//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVotePayloadResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    let poll: PollPayload?
    let vote: PollVotePayload?

    init(
        duration: String,
        poll: PollPayload? = nil,
        vote: PollVotePayload? = nil
    ) {
        self.duration = duration
        self.poll = poll
        self.vote = vote
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case poll
        case vote
    }
}
