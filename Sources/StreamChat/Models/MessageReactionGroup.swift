//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// All the reactions information about a specific type of reaction.
public struct ChatMessageReactionGroup: Equatable {
    /// The type of reaction.
    public let type: MessageReactionType
    /// The sum of all reaction scores for this type of reaction.
    public let sumScores: Int
    /// The amount of all reactions for this type of reaction.
    public let count: Int
    /// The date of the first reaction for this type of reaction.
    public let firstReactionAt: Date
    /// The date of the last reaction for this type of reaction.
    public let lastReactionAt: Date
}
