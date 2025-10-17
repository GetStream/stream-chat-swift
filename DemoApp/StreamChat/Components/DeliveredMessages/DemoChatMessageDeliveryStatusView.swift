//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatUI

class DemoChatMessageDeliveryStatusView: ChatMessageDeliveryStatusView {
    override func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        guard AppConfig.shared.demoAppConfig.isMessageDeliveredInfoEnabled else {
            return
        }

        let deliveredReads = content.channel.deliveredReads(for: content.message)
        // Message has been delivered but not read yet by someone
        if !deliveredReads.isEmpty && content.message.readByCount == 0 {
            messageDeliveryChekmarkView.imageView.image = appearance.images.messageDeliveryStatusRead
            messageDeliveryChekmarkView.imageView.tintColor = appearance.colorPalette.textLowEmphasis
        }
    }
}
