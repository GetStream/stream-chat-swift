//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsReactionGroup: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var count: Int
    var firstReactionAt: Date
    var lastReactionAt: Date

    init(count: Int, firstReactionAt: Date, lastReactionAt: Date) {
        self.count = count
        self.firstReactionAt = firstReactionAt
        self.lastReactionAt = lastReactionAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case count
        case firstReactionAt = "first_reaction_at"
        case lastReactionAt = "last_reaction_at"
    }

    static func == (lhs: FeedsReactionGroup, rhs: FeedsReactionGroup) -> Bool {
        lhs.count == rhs.count &&
            lhs.firstReactionAt == rhs.firstReactionAt &&
            lhs.lastReactionAt == rhs.lastReactionAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        hasher.combine(firstReactionAt)
        hasher.combine(lastReactionAt)
    }
}
