//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackMessageOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        options.remove([.flipped, .bubble, .timestamp, .avatar, .avatarSizePadding, .authorName, .threadInfo, .reactions])

        let isFirstInGroup: Bool = {
            let messageIndex = messages.index(messages.startIndex, offsetBy: indexPath.item)
            let message = messages[messageIndex]
            guard messageIndex < messages.index(before: messages.endIndex) else { return true }
            let previousMessage = messages[messages.index(after: messageIndex)]
            guard previousMessage.author == message.author else { return true }
            let delay = previousMessage.createdAt.timeIntervalSince(message.createdAt)
            return delay > minTimeIntervalBetweenMessagesInGroup
        }()

        if isFirstInGroup {
            options.insert([.avatar, .timestamp, .authorName])
        } else {
            options.insert(.avatarSizePadding)
        }

        return options
    }
}
