//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EnrichedActivity: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var actor: StreamData?
    var foreignId: String?
    var id: String?
    var latestReactions: [String: [EnrichedReaction]]?
    var object: StreamData?
    var origin: StreamData?
    var ownReactions: [String: [EnrichedReaction]]?
    var reactionCounts: [String: Int]?
    var score: Float?
    var target: StreamData?
    var to: [String]?
    var verb: String?

    init(actor: StreamData? = nil, foreignId: String? = nil, id: String? = nil, latestReactions: [String: [EnrichedReaction]]? = nil, object: StreamData? = nil, origin: StreamData? = nil, ownReactions: [String: [EnrichedReaction]]? = nil, reactionCounts: [String: Int]? = nil, score: Float? = nil, target: StreamData? = nil, to: [String]? = nil, verb: String? = nil) {
        self.actor = actor
        self.foreignId = foreignId
        self.id = id
        self.latestReactions = latestReactions
        self.object = object
        self.origin = origin
        self.ownReactions = ownReactions
        self.reactionCounts = reactionCounts
        self.score = score
        self.target = target
        self.to = to
        self.verb = verb
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actor
        case foreignId = "foreign_id"
        case id
        case latestReactions = "latest_reactions"
        case object
        case origin
        case ownReactions = "own_reactions"
        case reactionCounts = "reaction_counts"
        case score
        case target
        case to
        case verb
    }

    static func == (lhs: EnrichedActivity, rhs: EnrichedActivity) -> Bool {
        lhs.actor == rhs.actor &&
            lhs.foreignId == rhs.foreignId &&
            lhs.id == rhs.id &&
            lhs.latestReactions == rhs.latestReactions &&
            lhs.object == rhs.object &&
            lhs.origin == rhs.origin &&
            lhs.ownReactions == rhs.ownReactions &&
            lhs.reactionCounts == rhs.reactionCounts &&
            lhs.score == rhs.score &&
            lhs.target == rhs.target &&
            lhs.to == rhs.to &&
            lhs.verb == rhs.verb
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actor)
        hasher.combine(foreignId)
        hasher.combine(id)
        hasher.combine(latestReactions)
        hasher.combine(object)
        hasher.combine(origin)
        hasher.combine(ownReactions)
        hasher.combine(reactionCounts)
        hasher.combine(score)
        hasher.combine(target)
        hasher.combine(to)
        hasher.combine(verb)
    }
}
