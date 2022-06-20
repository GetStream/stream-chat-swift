//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

extension ChatMessageLayoutOption {
    static let pinInfo: Self = "pinInfo"
}

final class DemoChatMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: ChatChannel, with messages: AnyRandomAccessCollection<ChatMessage>, appearance: Appearance) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        guard indexPath.item < messages.count else {
            return options
        }
        
        let messageIndex = messages.index(messages.startIndex, offsetBy: indexPath.item)
        let message = messages[messageIndex]
        if message.isPinned {
            options.insert(.pinInfo)
        }
        return options
    }
}
