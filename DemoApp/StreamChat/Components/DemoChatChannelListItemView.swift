//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class DemoChatChannelListItemView: ChatChannelListItemView {
    override var subtitleText: String? {
        guard let previewMessage = content?.channel.previewMessage else {
            return super.subtitleText
        }

        if let location = previewMessage.sharedLocation {
            let text = location.isLive ? "Live location" : "Static location"
            return previewMessage.isSentByCurrentUser
                ? previewMessageTextForCurrentUser(messageText: text)
                : previewMessageTextFromAnotherUser(previewMessage.author, messageText: text)
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
        setMessageDeliveredInfoStateIfNeeded()
    }

    private func setMessageDeliveredInfoStateIfNeeded() {
        guard let content = self.content else { return }
        guard let previewMessage =  content.channel.previewMessage else { return }
        guard AppConfig.shared.demoAppConfig.isMessageDeliveredInfoEnabled else { return }

        let deliveredReads = content.channel.deliveredReads(for: previewMessage)
        // Message has been delivered but not read yet by someone
        if !deliveredReads.isEmpty && previewMessage.readByCount == 0 {
            previewMessageDeliveryStatusView.imageView.image = appearance.images.messageDeliveryStatusRead
            previewMessageDeliveryStatusView.imageView.tintColor = appearance.colorPalette.textLowEmphasis
        }
    }

}
