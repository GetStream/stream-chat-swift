//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var poll: PollResponseData?
    var vote: PollVoteResponseData?

    init(duration: String, poll: PollResponseData? = nil, vote: PollVoteResponseData? = nil) {
        self.duration = duration
        self.poll = poll
        self.vote = vote
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case poll
        case vote
    }

    static func == (lhs: PollVoteResponse, rhs: PollVoteResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.poll == rhs.poll &&
            lhs.vote == rhs.vote
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(poll)
        hasher.combine(vote)
    }
}
