//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryPollsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var next: String?
    /// Polls data returned by the query
    var polls: [PollResponseData]
    var prev: String?

    init(duration: String, next: String? = nil, polls: [PollResponseData], prev: String? = nil) {
        self.duration = duration
        self.next = next
        self.polls = polls
        self.prev = prev
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case polls
        case prev
    }

    static func == (lhs: QueryPollsResponse, rhs: QueryPollsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.polls == rhs.polls &&
            lhs.prev == rhs.prev
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(polls)
        hasher.combine(prev)
    }
}
