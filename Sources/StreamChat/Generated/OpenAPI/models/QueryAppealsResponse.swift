//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryAppealsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// List of Appeal Items
    var items: [AppealItemResponse]
    var next: String?
    var prev: String?

    init(duration: String, items: [AppealItemResponse], next: String? = nil, prev: String? = nil) {
        self.duration = duration
        self.items = items
        self.next = next
        self.prev = prev
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case items
        case next
        case prev
    }

    static func == (lhs: QueryAppealsResponse, rhs: QueryAppealsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.items == rhs.items &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(items)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
