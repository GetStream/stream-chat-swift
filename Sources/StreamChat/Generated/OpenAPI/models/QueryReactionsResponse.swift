//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryReactionsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var next: String?
    var prev: String?
    var reactions: [ReactionResponse]

    init(duration: String, next: String? = nil, prev: String? = nil, reactions: [ReactionResponse]) {
        self.duration = duration
        self.next = next
        self.prev = prev
        self.reactions = reactions
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case prev
        case reactions
    }

    static func == (lhs: QueryReactionsResponse, rhs: QueryReactionsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.reactions == rhs.reactions
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(reactions)
    }
}
