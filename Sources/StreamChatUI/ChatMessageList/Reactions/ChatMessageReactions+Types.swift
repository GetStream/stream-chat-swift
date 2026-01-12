//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The information of a reaction ready to be displayed in a view.
public struct ChatMessageReactionData: Equatable {
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
