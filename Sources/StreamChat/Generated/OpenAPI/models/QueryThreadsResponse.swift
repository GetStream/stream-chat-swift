//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryThreadsResponse: Sendable, Decodable {
    let next: String?
    /// List of enriched thread states
    let threads: [ThreadStateResponse]

    init(next: String? = nil, threads: [ThreadStateResponse]) {
        self.next = next
        self.threads = threads
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        case threads
    }
}
