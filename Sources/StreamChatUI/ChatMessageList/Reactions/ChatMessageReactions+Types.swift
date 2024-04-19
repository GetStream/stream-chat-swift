//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The information of a reaction ready to be displayed in a view.
public struct ChatMessageReactionData {
    /// The type of the reaction.
    public let type: MessageReactionType
    /// The score value of the reaction.
    public let score: Int
    /// A boolean value that determines if the current user added a reaction of this type.
    public let isChosenByCurrentUser: Bool
    /// The date of the first reaction from this type of reaction.
    public let firstReactionAt: Date?
    /// The date of the last reaction from this type of reaction.
    public let lastReactionAt: Date?

    public init(
        type: MessageReactionType,
        score: Int,
        isChosenByCurrentUser: Bool,
        firstReactionAt: Date? = nil,
        lastReactionAt: Date? = nil
    ) {
        self.type = type
        self.score = score
        self.isChosenByCurrentUser = isChosenByCurrentUser
        self.firstReactionAt = firstReactionAt
        self.lastReactionAt = lastReactionAt
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
