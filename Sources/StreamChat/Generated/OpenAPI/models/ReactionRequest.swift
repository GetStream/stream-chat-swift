//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date?
    var custom: [String: RawJSON]?
    /// Reaction score. If not specified reaction has score of 1
    var score: Int?
    /// The type of reaction (e.g. 'like', 'laugh', 'wow')
    var type: String
    /// Date/time of the last update
    var updatedAt: Date?

    init(createdAt: Date? = nil, custom: [String: RawJSON]? = nil, score: Int? = nil, type: String, updatedAt: Date? = nil) {
        self.createdAt = createdAt
        self.custom = custom
        self.score = score
        self.type = type
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case score
        case type
        case updatedAt = "updated_at"
    }

    static func == (lhs: ReactionRequest, rhs: ReactionRequest) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.score == rhs.score &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(score)
        hasher.combine(type)
        hasher.combine(updatedAt)
    }
}
