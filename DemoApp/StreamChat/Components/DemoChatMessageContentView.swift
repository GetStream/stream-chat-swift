//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoChatMessageContentView: ChatMessageContentView {
    var pinInfoLabel: UILabel?

    lazy var saveForLaterView: UIView = {
        HContainer(spacing: 4) {
            saveForLaterIcon
                .height(12)
                .width(12)
            saveForLaterLabel
                .height(30)
        }
    }()

    lazy var saveForLaterIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "bookmark.fill")
        imageView.tintColor = appearance.colorPalette.accentPrimary
        return imageView
    }()

    lazy var saveForLaterLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved for later"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.accentPrimary
        return label
    }()

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        if options.contains(.pinInfo) {
            backgroundColor = UIColor(red: 0.984, green: 0.957, blue: 0.867, alpha: 1)
            pinInfoLabel = UILabel()
            pinInfoLabel?.font = appearance.fonts.footnote
            pinInfoLabel?.textColor = appearance.colorPalette.textLowEmphasis
            bubbleThreadFootnoteContainer.insertArrangedSubview(pinInfoLabel!, at: 0)
        }

        if options.contains(.saveForLaterInfo) {
            backgroundColor = appearance.colorPalette.highlightedAccentBackground1
            bubbleThreadFootnoteContainer.insertArrangedSubview(saveForLaterView, at: 0)
            saveForLaterView.topAnchor.constraint(
                equalTo: bubbleThreadFootnoteContainer.topAnchor,
                constant: 4
            ).isActive = true
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

        if content?.deletedForMe == true {
            timestampLabel?.text?.append(" - Deleted only for me")
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
