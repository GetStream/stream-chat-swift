//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendReactionRequest: Sendable, Encodable, JSONEncodable {
    /// Whether to replace all existing user reactions
    let enforceUnique: Bool?
    /// Represents user reaction to a message
    let reaction: ReactionRequest
    /// Skips any mobile push notifications
    let skipPush: Bool?

    init(enforceUnique: Bool? = nil, reaction: ReactionRequest, skipPush: Bool? = nil) {
        self.enforceUnique = enforceUnique
        self.reaction = reaction
        self.skipPush = skipPush
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enforceUnique = "enforce_unique"
        case reaction
        case skipPush = "skip_push"
    }
}
