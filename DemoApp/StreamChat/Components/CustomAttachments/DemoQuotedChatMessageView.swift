//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoQuotedChatMessageView: QuotedChatMessageView {
    override func setAttachmentPreview(for message: ChatMessage) {
        let locationAttachments = message.staticLocationAttachments
        if let locationPayload = locationAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = UIImage(
                systemName: "mappin.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(font: .boldSystemFont(ofSize: 12))
            )
            attachmentPreviewView.tintColor = .systemRed
            textView.text = """
            Location:
            (\(locationPayload.latitude),\(locationPayload.longitude))
            """
            return
        }

        super.setAttachmentPreview(for: message)
    }
}
