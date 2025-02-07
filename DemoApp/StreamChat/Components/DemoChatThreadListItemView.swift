//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class DemoChatThreadListItemView: ChatThreadListItemView {
    override var replyPreviewText: String? {
        if let draftMessage = content?.thread.parentMessage.draftReply {
            return "Draft: \(draftMessage.text)"
        }
        return super.replyPreviewText
    }

    override func updateContent() {
        super.updateContent()

        if content?.thread.parentMessage.draftReply != nil {
            // Highlight Draft text in replyDescriptionLabel using attributed string
            let attributedString = NSMutableAttributedString(string: replyDescriptionLabel.text ?? "")
            if let range = (replyDescriptionLabel.text as NSString?)?.range(of: "Draft:") {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: appearance.colorPalette.accentPrimary,
                    range: range
                )
                attributedString.addAttribute(
                    .font,
                    value: appearance.fonts.footnoteBold,
                    range: range
                )
            }
            replyDescriptionLabel.attributedText = attributedString
        }
    }
}
