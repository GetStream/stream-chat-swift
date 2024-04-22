//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The information of a reaction ready to be displayed in a view.
public struct ChatMessageReactionData {
    /// The type of the reaction.
    public let type: MessageReactionType
    /// The score value of the reaction. By default it is the same value as `count`.
    public let score: Int
    /// The number of reactions.
    public let count: Int
    /// A boolean value that determines if the current user added a reaction of this type.
    public let isChosenByCurrentUser: Bool
    /// The date of the first reaction from this type of reaction.
    /// Can be `nil` if data was not created by the new `ChatMessageReactionGroup`.
    public let firstReactionAt: Date?
    /// The date of the last reaction from this type of reaction.
    /// Can be `nil` if data was not created by the new `ChatMessageReactionGroup`.
    public let lastReactionAt: Date?

    public init(
        type: MessageReactionType,
        score: Int,
        isChosenByCurrentUser: Bool,
        count: Int? = nil,
        firstReactionAt: Date? = nil,
        lastReactionAt: Date? = nil
    ) {
        self.type = type
        self.score = score
        self.count = count ?? score
        self.isChosenByCurrentUser = isChosenByCurrentUser
        self.firstReactionAt = firstReactionAt
        self.lastReactionAt = lastReactionAt
    }

    public init(
        reactionGroup: ChatMessageReactionGroup,
        isChosenByCurrentUser: Bool
    ) {
        type = reactionGroup.type
        score = reactionGroup.sumScores
        count = reactionGroup.count
        firstReactionAt = reactionGroup.firstReactionAt
        lastReactionAt = reactionGroup.lastReactionAt
        self.isChosenByCurrentUser = isChosenByCurrentUser
    }
}

public enum ChatMessageReactionsBubbleStyle {
    case bigIncoming
    case smallIncoming
    case bigOutgoing
    case smallOutgoing
}

extension ChatMessageReactionsBubbleStyle {
    var isBig: Bool {
        self == .bigIncoming || self == .bigOutgoing
    }

    var isIncoming: Bool {
        self == .bigIncoming || self == .smallIncoming
    }
}

/// Default reactions sorting provided by Stream.
public enum ReactionSorting {
    /// Sorting by score.
    public static func byScore() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            lhs.score > rhs.score
        }
    }

    /// Sorting by count.
    public static func byCount() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            lhs.count > rhs.count
        }
    }

    /// Sorting by firstReactionAt.
    public static func byFirstReactionAt() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            guard let lhsFirstReactionAt = lhs.firstReactionAt, let rhsFirstReactionAt = rhs.firstReactionAt else {
                return false
            }

            return lhsFirstReactionAt < rhsFirstReactionAt
        }
    }

    /// Sorting by lastReactionAt.
    public static func byLastReactionAt() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            guard let lhsLastReactionAt = lhs.lastReactionAt, let rhsLastReactionAt = rhs.lastReactionAt else {
                return false
            }

            return lhsLastReactionAt > rhsLastReactionAt
        }
    }

    /// Sorting by firstReactionAt and count.
    public static func byFirstReactionAtAndCount() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            if lhs.count == rhs.count {
                return ReactionSorting.byFirstReactionAt()(lhs, rhs)
            }

            return lhs.count > rhs.count
        }
    }

    /// Sorting by lastReactionAt and count.
    public static func byLastReactionAtAndCount() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            if lhs.count == rhs.count {
                return ReactionSorting.byLastReactionAt()(lhs, rhs)
            }

            return lhs.count > rhs.count
        }
    }

    /// Sorting by firstReactionAt and score.
    public static func byFirstReactionAtAndScore() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            if lhs.score == rhs.score {
                return ReactionSorting.byFirstReactionAt()(lhs, rhs)
            }

            return lhs.score > rhs.score
        }
    }

    /// Sorting by lastReactionAt and score.
    public static func byLastReactionAtAndScore() -> (ChatMessageReactionData, ChatMessageReactionData) -> Bool {
        { lhs, rhs in
            if lhs.score == rhs.score {
                return ReactionSorting.byLastReactionAt()(lhs, rhs)
            }

            return lhs.score > rhs.score
        }
    }
}
