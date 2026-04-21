//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVotesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var next: String?
    var prev: String?
    /// Poll votes
    var votes: [PollVoteResponseData]

    init(duration: String, next: String? = nil, prev: String? = nil, votes: [PollVoteResponseData]) {
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

    static func == (lhs: PollVotesResponse, rhs: PollVotesResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.votes == rhs.votes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(votes)
    }
}
