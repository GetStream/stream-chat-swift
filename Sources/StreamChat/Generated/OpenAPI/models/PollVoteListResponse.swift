//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteListResponse: Sendable, Decodable {
    let next: String?
    let prev: String?
    /// Poll votes
    let votes: [PollVotePayload]

    init(next: String? = nil, prev: String? = nil, votes: [PollVotePayload]) {
        self.next = next
        self.prev = prev
        self.votes = votes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
        self.votes = try container.decode([PollVotePayload].self, forKey: .votes)
    }
}
