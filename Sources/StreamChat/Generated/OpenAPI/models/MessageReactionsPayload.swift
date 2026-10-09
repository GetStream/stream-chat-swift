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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.reactions = try container.decodeArrayIgnoringFailures(
            [MessageReactionPayload].self,
            forKey: .reactions
        )
    }
}
