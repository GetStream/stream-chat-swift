//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageReactionsPayload: Sendable, Decodable {
    /// List of reactions
    let reactions: [MessageReactionPayload]

    init(reactions: [MessageReactionPayload]) {
        self.reactions = reactions
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case reactions
    }
}
