//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CastPollVoteRequestBody: Sendable, Encodable, JSONEncodable {
    let vote: VoteDataRequestBody?

    init(vote: VoteDataRequestBody? = nil) {
        self.vote = vote
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(vote, forKey: .vote)
    }
}
