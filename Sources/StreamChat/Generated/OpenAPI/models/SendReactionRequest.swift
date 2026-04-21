//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendReactionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Whether to replace all existing user reactions
    var enforceUnique: Bool?
    var reaction: ReactionRequest
    /// Skips any mobile push notifications
    var skipPush: Bool?

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

    static func == (lhs: SendReactionRequest, rhs: SendReactionRequest) -> Bool {
        lhs.enforceUnique == rhs.enforceUnique &&
            lhs.reaction == rhs.reaction &&
            lhs.skipPush == rhs.skipPush
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enforceUnique)
        hasher.combine(reaction)
        hasher.combine(skipPush)
    }
}
