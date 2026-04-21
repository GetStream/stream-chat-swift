//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CastPollVoteRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var vote: VoteData?

    init(vote: VoteData? = nil) {
        self.vote = vote
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case vote
    }

    static func == (lhs: CastPollVoteRequest, rhs: CastPollVoteRequest) -> Bool {
        lhs.vote == rhs.vote
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(vote)
    }
}
