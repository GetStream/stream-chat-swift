//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryDraftsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Drafts
    var drafts: [DraftResponse]
    /// Duration of the request in milliseconds
    var duration: String
    var next: String?
    var prev: String?

    init(drafts: [DraftResponse], duration: String, next: String? = nil, prev: String? = nil) {
        self.drafts = drafts
        self.duration = duration
        self.next = next
        self.prev = prev
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case drafts
        case duration
        case next
        case prev
    }

    static func == (lhs: QueryDraftsResponse, rhs: QueryDraftsResponse) -> Bool {
        lhs.drafts == rhs.drafts &&
            lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(drafts)
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
