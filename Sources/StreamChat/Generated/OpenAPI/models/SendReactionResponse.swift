//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class SendReactionResponse: Sendable, Decodable {
    /// Represents any chat message
    let message: MessageResponse
    let reaction: MessageReactionPayload

    init(message: MessageResponse, reaction: MessageReactionPayload) {
        self.message = message
        self.reaction = reaction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.message = try container.decode(MessageResponse.self, forKey: .message)
        self.reaction = try container.decode(MessageReactionPayload.self, forKey: .reaction)
    }
}
