//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendReactionResponse: Sendable, Decodable {
    /// Represents any chat message
    let message: MessageResponse
    let reaction: MessageReactionPayload

    init(message: MessageResponse, reaction: MessageReactionPayload) {
        self.message = message
        self.reaction = reaction
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        case reaction
    }
}
