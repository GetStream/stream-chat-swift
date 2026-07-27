//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CastPollVoteRequest: Sendable, Codable, JSONEncodable {
    let vote: VoteData?

    init(vote: VoteData? = nil) {
        self.vote = vote
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case vote
    }
}
