//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionRequest: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    /// Reaction score. If not specified reaction has score of 1
    let score: Int?
    /// The type of reaction (e.g. 'like', 'laugh', 'wow')
    let type: MessageReactionType

    init(custom: [String: RawJSON]? = nil, score: Int? = nil, type: MessageReactionType) {
        self.custom = custom
        self.score = score
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case score
        case type
    }
}
