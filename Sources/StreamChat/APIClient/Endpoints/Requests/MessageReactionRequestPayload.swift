//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `message/[message_id]/reaction` endpoint
struct MessageReactionRequestPayload: Encodable {
    enum CodingKeys: String, CodingKey {
        case enforceUnique = "enforce_unique"
        case reaction
        case skipPush = "skip_push"
    }

    let enforceUnique: Bool
    let skipPush: Bool
    let reaction: ReactionRequestPayload

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enforceUnique, forKey: .enforceUnique)
        try container.encode(skipPush, forKey: .skipPush)
        try container.encode(reaction, forKey: .reaction)
    }
}

struct ReactionRequestPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
        case emojiCode = "emoji_code"
    }

    let type: MessageReactionType
    let score: Int
    let emojiCode: String?
    let extraData: [String: RawJSON]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(score, forKey: .score)
        try container.encodeIfPresent(emojiCode, forKey: .emojiCode)
        try extraData.encode(to: encoder)
    }
}
