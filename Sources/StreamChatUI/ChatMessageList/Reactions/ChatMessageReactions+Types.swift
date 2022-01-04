//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct ChatMessageReactionData {
    public let type: MessageReactionType
    public let score: Int
    public let isChosenByCurrentUser: Bool

    public init(type: MessageReactionType, score: Int, isChosenByCurrentUser: Bool) {
        self.type = type
        self.score = score
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
