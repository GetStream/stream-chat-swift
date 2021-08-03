//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `message/[message_id]/reaction` endpoint
struct MessageReactionRequestPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
        case enforceUnique = "enforce_unique"
    }
    
    let type: MessageReactionType
    let score: Int
    let enforceUnique: Bool
    let extraData: [String: RawJSON]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(score, forKey: .score)
        try container.encode(enforceUnique, forKey: .enforceUnique)
        try extraData.encode(to: encoder)
    }
}
