//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteResponse: Sendable, Codable, JSONEncodable {
    let poll: PollResponseData?
    let vote: PollVoteResponseData?

    init(
        poll: PollResponseData? = nil,
        vote: PollVoteResponseData? = nil
    ) {
        self.poll = poll
        self.vote = vote
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case poll
        case vote
    }
}
