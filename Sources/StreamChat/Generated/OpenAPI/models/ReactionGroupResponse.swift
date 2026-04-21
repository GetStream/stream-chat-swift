//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionGroupResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Count is the number of reactions of this type.
    var count: Int
    /// FirstReactionAt is the time of the first reaction of this type. This is the same also if all reaction of this type are deleted, because if someone will react again with the same type, will be preserved the sorting.
    var firstReactionAt: Date
    /// LastReactionAt is the time of the last reaction of this type.
    var lastReactionAt: Date
    /// The most recent users who reacted with this type, ordered by most recent first.
    var latestReactionsBy: [ReactionGroupUserResponse]
    /// SumScores is the sum of all scores of reactions of this type. Medium allows you to clap articles more than once and shows the sum of all claps from all users. For example, you can send `clap` x5 using `score: 5`.
    var sumScores: Int

    init(count: Int, firstReactionAt: Date, lastReactionAt: Date, latestReactionsBy: [ReactionGroupUserResponse], sumScores: Int) {
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

    static func == (lhs: ReactionGroupResponse, rhs: ReactionGroupResponse) -> Bool {
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
