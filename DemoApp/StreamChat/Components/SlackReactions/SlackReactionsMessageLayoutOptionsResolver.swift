//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

extension ChatMessageLayoutOption {
    static let customReactions: Self = "customReactions"
}

final class SlackReactionsMessageLayoutOptionsResolver: DemoChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        guard indexPath.item < messages.count else {
            return options
        }

        let messageIndex = messages.index(messages.startIndex, offsetBy: indexPath.item)
        let message = messages[messageIndex]

        options.remove(.reactions)
        if channel.ownCapabilities.contains(.sendReaction) && !message.reactionScores.isEmpty {
            options.insert(.customReactions)
        }

        return options
    }
}
