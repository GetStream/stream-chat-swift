//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `message/[message_id]/reaction` endpoint
struct MessageReactionRequestPayload<ExtraData: MessageReactionExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
    }
    
    let type: MessageReactionType
    let score: Int
    let extraData: ExtraData
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(score, forKey: .score)
        try extraData.encode(to: encoder)
    }
}
