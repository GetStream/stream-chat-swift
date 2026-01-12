//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The payload of reactions grouped by type.
struct MessageReactionGroupPayload: Decodable, Equatable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case sumScores = "sum_scores"
        case count
        case firstReactionAt = "first_reaction_at"
        case lastReactionAt = "last_reaction_at"
    }

    let sumScores: Int
    let count: Int
    let firstReactionAt: Date
    let lastReactionAt: Date

    init(
        sumScores: Int,
        count: Int,
        firstReactionAt: Date,
        lastReactionAt: Date
    ) {
        self.sumScores = sumScores
        self.count = count
        self.firstReactionAt = firstReactionAt
        self.lastReactionAt = lastReactionAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sumScores = try container.decode(Int.self, forKey: .sumScores)
        count = try container.decode(Int.self, forKey: .count)
        firstReactionAt = try container.decode(Date.self, forKey: .firstReactionAt)
        lastReactionAt = try container.decode(Date.self, forKey: .lastReactionAt)
    }
}
