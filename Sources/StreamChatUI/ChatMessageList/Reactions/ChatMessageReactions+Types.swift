//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct ChatMessageReactionData {
    public let type: MessageReactionType
    public let score: Int
    public let isChosenByCurrentUser: Bool
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
