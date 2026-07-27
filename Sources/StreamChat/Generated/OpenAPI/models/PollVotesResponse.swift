//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVotesResponse: Sendable, Codable, JSONEncodable {
    let next: String?
    let prev: String?
    /// Poll votes
    let votes: [PollVoteResponseData]

    init(
        next: String? = nil,
        prev: String? = nil,
        votes: [PollVoteResponseData]
    ) {
        self.next = next
        self.prev = prev
        self.votes = votes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        case prev
        case votes
    }
}
