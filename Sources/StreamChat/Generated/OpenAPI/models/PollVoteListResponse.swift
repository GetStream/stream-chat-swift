//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteListResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    let next: String?
    let prev: String?
    /// Poll votes
    let votes: [PollVotePayload?]

    init(
        duration: String,
        next: String? = nil,
        prev: String? = nil,
        votes: [PollVotePayload?]
    ) {
        self.duration = duration
        self.next = next
        self.prev = prev
        self.votes = votes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case prev
        case votes
    }
}
