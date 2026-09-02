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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case poll
        case vote
    }
}
