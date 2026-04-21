//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryThreadsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var next: String?
    var prev: String?
    /// List of enriched thread states
    var threads: [ThreadStateResponse]

    init(duration: String, next: String? = nil, prev: String? = nil, threads: [ThreadStateResponse]) {
        self.duration = duration
        self.next = next
        self.prev = prev
        self.threads = threads
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case prev
        case threads
    }

    static func == (lhs: QueryThreadsResponse, rhs: QueryThreadsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.threads == rhs.threads
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(threads)
    }
}
