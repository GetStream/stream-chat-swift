//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@_spi(ExperimentalLocation)
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatChannelListItemView: ChatChannelListItemView {
    override var subtitleText: String? {
        guard let previewMessage = content?.channel.previewMessage else {
            return super.subtitleText
        }
        if previewMessage.liveLocationAttachments.isEmpty == false {
            return previewMessage.isSentByCurrentUser
                ? previewMessageTextForCurrentUser(messageText: "Live location")
                : previewMessageTextFromAnotherUser(previewMessage.author, messageText: "Live Location")
        }
        
        if previewMessage.staticLocationAttachments.isEmpty == false {
            return previewMessage.isSentByCurrentUser
                ? previewMessageTextForCurrentUser(messageText: "Static location")
                : previewMessageTextFromAnotherUser(previewMessage.author, messageText: "Static Location")
        }
        return super.subtitleText
    }

    override var contentBackgroundColor: UIColor {
        // In case it is a message search, we want to ignore the pinning behaviour.
        if content?.searchResult?.message != nil {
            return super.contentBackgroundColor
        }
        if content?.channel.isPinned == true {
            return appearance.colorPalette.pinnedMessageBackground
        }
        return super.contentBackgroundColor
    }

    override func updateContent() {
        super.updateContent()

        backgroundColor = contentBackgroundColor
    }
}
