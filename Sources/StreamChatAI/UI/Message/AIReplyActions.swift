//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How the person rated a reply.
public enum AIMessageRating: Hashable, Sendable {
    /// A good reply.
    case positive
    /// A bad reply.
    case negative
}

/// What ``AIReplyActionsView`` offers besides copying and sharing a reply.
public struct AIReplyActions {
    /// How the person rated the reply, if they did.
    public var rating: AIMessageRating?
    /// Asks the agent for a new reply in its place.
    public var onRegenerate: (@MainActor () -> Void)?
    /// Rates the reply, or takes the rating back with nil.
    public var onRate: (@MainActor (AIMessageRating?) -> Void)?

    public init(
        rating: AIMessageRating? = nil,
        onRegenerate: (@MainActor () -> Void)? = nil,
        onRate: (@MainActor (AIMessageRating?) -> Void)? = nil
    ) {
        self.rating = rating
        self.onRegenerate = onRegenerate
        self.onRate = onRate
    }
}
