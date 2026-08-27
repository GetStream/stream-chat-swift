//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A type representing a message reaction. `ChatMessageReaction` is an immutable snapshot
/// of a message reaction entity at the given time.
public final class ChatMessageReaction: Identifiable, Sendable {
    /// The id of the reaction.
    public let id: String

    /// The reaction type.
    public let type: MessageReactionType

    /// The reaction score.
    public let score: Int

    /// The date the reaction was created.
    public let createdAt: Date

    /// The date the reaction was last updated.
    public let updatedAt: Date

    /// The author.
    public let author: ChatUser

    /// Custom data
    public let extraData: [String: RawJSON]

    init(
        id: String,
        type: MessageReactionType,
        score: Int,
        createdAt: Date,
        updatedAt: Date,
        author: ChatUser,
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.type = type
        self.score = score
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.extraData = extraData
    }
}

extension ChatMessageReaction: Hashable {
    public static func == (lhs: ChatMessageReaction, rhs: ChatMessageReaction) -> Bool {
        lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.score == rhs.score &&
            lhs.createdAt == rhs.createdAt &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.author == rhs.author &&
            lhs.extraData == rhs.extraData
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
