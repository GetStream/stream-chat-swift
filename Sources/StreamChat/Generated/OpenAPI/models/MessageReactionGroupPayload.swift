//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageReactionGroupPayload: Sendable, Decodable {
    /// Count is the number of reactions of this type.
    let count: Int
    /// FirstReactionAt is the time of the first reaction of this type. This is the same also if all reaction of this type are deleted, because if someone will react again with the same type, will be preserved the sorting.
    let firstReactionAt: Date
    /// LastReactionAt is the time of the last reaction of this type.
    let lastReactionAt: Date
    /// SumScores is the sum of all scores of reactions of this type. Medium allows you to clap articles more than once and shows the sum of all claps from all users. For example, you can send `clap` x5 using `score: 5`.
    let sumScores: Int

    init(count: Int, firstReactionAt: Date, lastReactionAt: Date, sumScores: Int) {
        self.count = count
        self.firstReactionAt = firstReactionAt
        self.lastReactionAt = lastReactionAt
        self.sumScores = sumScores
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case count
        case firstReactionAt = "first_reaction_at"
        case lastReactionAt = "last_reaction_at"
        case sumScores = "sum_scores"
    }
}
