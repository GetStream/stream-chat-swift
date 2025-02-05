//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class DemoChatChannelListItemView: ChatChannelListItemView {
    override var subtitleText: String? {
        if let draftMessage = content?.channel.draftMessage {
            return "Draft: \(draftMessage.text)"
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

        if content?.channel.draftMessage != nil {
            // Highlight Draft text in subtitleLabel using attributed string
            let attributedString = NSMutableAttributedString(string: subtitleLabel.text ?? "")
            if let range = (subtitleLabel.text as NSString?)?.range(of: "Draft:") {
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
            subtitleLabel.attributedText = attributedString
        }
    }
}
