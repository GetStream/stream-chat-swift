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

        let deliveredReads = content.channel.reads
            .filter { read in
                read.lastDeliveredAt ?? .distantPast > content.message.createdAt
                && read.user.id != content.message.author.id
            }

        if !deliveredReads.isEmpty && content.message.readByCount == 0 {
            messageDeliveryChekmarkView.imageView.image = appearance.images.messageDeliveryStatusRead
            messageDeliveryChekmarkView.imageView.tintColor = appearance.colorPalette.textLowEmphasis
        }
    }
}
