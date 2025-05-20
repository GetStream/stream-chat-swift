//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoQuotedChatMessageView: QuotedChatMessageView {
    override func setAttachmentPreview(for message: ChatMessage) {
        if message.staticLocationAttachments.isEmpty == false {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = UIImage(systemName: "mappin.circle.fill")
            attachmentPreviewView.tintColor = .systemRed
            textView.text = "Location"
            return
        }

        if message.liveLocationAttachments.isEmpty == false {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = UIImage(systemName: "location.fill")
            attachmentPreviewView.tintColor = .systemBlue
            textView.text = "Live Location"
            return
        }

        super.setAttachmentPreview(for: message)
    }
}
