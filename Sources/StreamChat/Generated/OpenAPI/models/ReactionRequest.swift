//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionRequest: Sendable, Encodable, JSONEncodable {
    /// Date/time of creation
    let createdAt: Date?
    let custom: [String: RawJSON]?
    /// Reaction score. If not specified reaction has score of 1
    let score: Int?
    /// The type of reaction (e.g. 'like', 'laugh', 'wow')
    let type: MessageReactionType
    /// Date/time of the last update
    let updatedAt: Date?

    init(
        createdAt: Date? = nil,
        custom: [String: RawJSON]? = nil,
        score: Int? = nil,
        type: MessageReactionType,
        updatedAt: Date? = nil
    ) {
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
}
