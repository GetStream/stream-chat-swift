//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteListResponse: Sendable, Decodable {
    let next: String?
    /// Poll votes
    let votes: [PollVotePayload]

    init(next: String? = nil, votes: [PollVotePayload]) {
        self.next = next
        self.votes = votes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        case votes
    }
}
