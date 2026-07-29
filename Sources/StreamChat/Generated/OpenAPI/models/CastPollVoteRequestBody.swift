//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CastPollVoteRequestBody: Sendable, Codable, JSONEncodable {
    let vote: VoteDataRequestBody?

    init(vote: VoteDataRequestBody? = nil) {
        self.vote = vote
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case vote
    }
}
