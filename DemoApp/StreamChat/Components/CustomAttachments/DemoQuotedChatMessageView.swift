//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoQuotedChatMessageView: QuotedChatMessageView {
    override func setAttachmentPreview(for message: ChatMessage) {
        let locationAttachments = message.attachments(payloadType: LocationAttachmentPayload.self)
        if let locationPayload = locationAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = UIImage(
                systemName: "mappin.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(font: .boldSystemFont(ofSize: 12))
            )
            attachmentPreviewView.tintColor = .systemRed
            textView.text = """
            Location:
            (\(locationPayload.coordinate.latitude),\(locationPayload.coordinate.longitude))
            """
            return
        }

        super.setAttachmentPreview(for: message)
    }
}
