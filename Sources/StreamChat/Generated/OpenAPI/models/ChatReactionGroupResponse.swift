//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatReactionGroupResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var count: Int
    var firstReactionAt: Date
    var lastReactionAt: Date
    var latestReactionsBy: [ChatReactionGroupUserResponse]
    var sumScores: Int

    init(count: Int, firstReactionAt: Date, lastReactionAt: Date, latestReactionsBy: [ChatReactionGroupUserResponse], sumScores: Int) {
        self.count = count
        self.firstReactionAt = firstReactionAt
        self.lastReactionAt = lastReactionAt
        self.latestReactionsBy = latestReactionsBy
        self.sumScores = sumScores
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case count
        case firstReactionAt = "first_reaction_at"
        case lastReactionAt = "last_reaction_at"
        case latestReactionsBy = "latest_reactions_by"
        case sumScores = "sum_scores"
    }

    static func == (lhs: ChatReactionGroupResponse, rhs: ChatReactionGroupResponse) -> Bool {
        lhs.count == rhs.count &&
            lhs.firstReactionAt == rhs.firstReactionAt &&
            lhs.lastReactionAt == rhs.lastReactionAt &&
            lhs.latestReactionsBy == rhs.latestReactionsBy &&
            lhs.sumScores == rhs.sumScores
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        hasher.combine(firstReactionAt)
        hasher.combine(lastReactionAt)
        hasher.combine(latestReactionsBy)
        hasher.combine(sumScores)
    }
}
