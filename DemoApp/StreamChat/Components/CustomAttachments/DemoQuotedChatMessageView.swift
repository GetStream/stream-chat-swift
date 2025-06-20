//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoQuotedChatMessageView: QuotedChatMessageView {
    override func updateContent() {
        super.updateContent()

        if let sharedLocation = content?.message.sharedLocation {
            if sharedLocation.isLive {
                attachmentPreviewView.contentMode = .scaleAspectFit
                attachmentPreviewView.image = UIImage(systemName: "location.fill")
                attachmentPreviewView.tintColor = .systemBlue
                textView.text = "Live Location"
            } else {
                attachmentPreviewView.contentMode = .scaleAspectFit
                attachmentPreviewView.image = UIImage(systemName: "mappin.circle.fill")
                attachmentPreviewView.tintColor = .systemRed
                textView.text = "Location"
            }
        }
    }
}
