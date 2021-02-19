//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal struct ChatMessageReactionData {
    internal let type: MessageReactionType
    internal let isChosenByCurrentUser: Bool
}

internal enum ChatMessageReactionsBubbleStyle {
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
