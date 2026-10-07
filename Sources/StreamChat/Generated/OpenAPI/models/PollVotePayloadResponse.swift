//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVotePayloadResponse: Sendable, Decodable {
    let poll: PollPayload?
    let vote: PollVotePayload?

    init(poll: PollPayload? = nil, vote: PollVotePayload? = nil) {
        self.poll = poll
        self.vote = vote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.poll = try container.decodeIfPresent(PollPayload.self, forKey: .poll)
        self.vote = try container.decodeIfPresent(PollVotePayload.self, forKey: .vote)
    }
}
