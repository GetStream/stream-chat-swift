//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a message reaction. `ChatMessageReaction` is an immutable snapshot
/// of a message reaction entity at the given time.
public struct ChatMessageReaction: Hashable {
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

    public init(
        type: MessageReactionType,
        score: Int,
        createdAt: Date,
        updatedAt: Date,
        author: ChatUser,
        extraData: [String: RawJSON]
    ) {
        self.type = type
        self.score = score
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.extraData = extraData
    }
}
