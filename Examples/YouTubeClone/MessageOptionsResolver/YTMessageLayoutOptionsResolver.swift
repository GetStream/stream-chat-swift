//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class YTMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        
        // Remove the message options that are not needed in our case
        options.remove([
            .flipped,
            .bubble,
            .timestamp,
            .avatar,
            .avatarSizePadding,
            .authorName,
            .threadInfo,
            .reactions,
            .onlyVisibleToYouIndicator,
            .errorIndicator
        ])
        
        // Insert the message options that are needed
        options.insert([.avatar, .timestamp, .authorName])
        
        return options
    }
}
