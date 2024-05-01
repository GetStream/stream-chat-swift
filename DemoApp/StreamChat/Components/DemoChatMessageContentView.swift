//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoChatMessageContentView: ChatMessageContentView {
    var pinInfoLabel: UILabel?

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        if options.contains(.pinInfo) {
            backgroundColor = UIColor(red: 0.984, green: 0.957, blue: 0.867, alpha: 1)
            pinInfoLabel = UILabel()
            pinInfoLabel?.font = appearance.fonts.footnote
            pinInfoLabel?.textColor = appearance.colorPalette.textLowEmphasis
            bubbleThreadFootnoteContainer.insertArrangedSubview(pinInfoLabel!, at: 0)
        }
    }

    override func updateContent() {
        super.updateContent()

        if content?.isShadowed == true {
            textView?.textColor = appearance.colorPalette.textLowEmphasis
            textView?.text = "This message is from a shadow banned user"
        }

        /// If automatic translation is added, do not show manual translation
        /// (Demo App only feature to test LLC manual translation)
        if layoutOptions?.contains(.translation) == false,
           content?.isDeleted == false,
           let translations = content?.translations,
           let turkishTranslation = translations[.turkish] {
            textView?.text = turkishTranslation
            timestampLabel?.text?.append(" - Translated to Turkish")
        }

        if content?.isPinned == true, let pinInfoLabel = pinInfoLabel {
            pinInfoLabel.text = "📌 Pinned"
            if let pinDetails = content?.pinDetails {
                let pinnedByName = pinDetails.pinnedBy.id == UserDefaults.shared.currentUserId
                    ? "You"
                    : pinDetails.pinnedBy.name ?? pinDetails.pinnedBy.id
                pinInfoLabel.text?.append(" by \(pinnedByName)")
            }
        }

        if let authorNameLabel = authorNameLabel, authorNameLabel.text?.isEmpty == true,
           let birthLand = content?.author.birthLand {
            authorNameLabel.text?.append(" \(birthLand)")
        }
    }
}
