//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoChatMessageContentView: ChatMessageContentView {
    var pinInfoLabel: UILabel?

    private static let premiumBorderColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
    private static let premiumBorderWidth: CGFloat = 2

    private var defaultLinkTextAttributes: [NSAttributedString.Key: Any]?

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
            backgroundColor = appearance.colorPalette.backgroundCoreHighlight
            pinInfoLabel = UILabel()
            pinInfoLabel?.font = appearance.fonts.footnote
            pinInfoLabel?.textColor = appearance.colorPalette.textTertiary
            bubbleThreadFootnoteContainer.insertArrangedSubview(pinInfoLabel!, at: 0)
        }

        if options.contains(.saveForLaterInfo) {
            backgroundColor = appearance.colorPalette.backgroundCoreElevation1
            bubbleThreadFootnoteContainer.insertArrangedSubview(saveForLaterView, at: 0)
            saveForLaterView.topAnchor.constraint(
                equalTo: bubbleThreadFootnoteContainer.topAnchor,
                constant: 4
            ).isActive = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePremiumAvatarBorder()
    }

    override func updateContent() {
        super.updateContent()

        if content?.isShadowed == true {
            textView?.textColor = appearance.colorPalette.textTertiary
            textView?.text = "This message is from a shadow banned user"
        }

        /// If the system message is flagged as a warning in its extra data, render
        /// it in yellow between two warning emojis.
        /// (Demo App only feature to QA extra data in system messages)
        if content?.isWarningSystemMessage == true, let text = content?.text {
            textView?.textColor = .systemYellow
            textView?.text = "⚠️ \(text) ⚠️"
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

        updatePremiumAvatarBorder()
        updatePremiumMentionColors()
    }

    private func updatePremiumAvatarBorder() {
        guard let avatarView = authorAvatarView?.presenceAvatarView.avatarView else { return }

        let shouldShowPremiumBorder = AppConfig.shared.demoAppConfig.shouldShowPremiumBadge
            && content?.member?.isPremium == true

        if shouldShowPremiumBorder {
            let radius = min(avatarView.bounds.width, avatarView.bounds.height) / 2
            avatarView.layer.cornerRadius = radius
            avatarView.layer.borderWidth = Self.premiumBorderWidth
            avatarView.layer.borderColor = Self.premiumBorderColor.cgColor
        } else {
            avatarView.layer.cornerRadius = 0
            avatarView.layer.borderWidth = 0
            avatarView.layer.borderColor = nil
        }
    }

    private func updatePremiumMentionColors() {
        guard let textView else { return }

        if defaultLinkTextAttributes == nil {
            defaultLinkTextAttributes = textView.linkTextAttributes
        }

        let defaultLinkColor = tintColor ?? appearance.colorPalette.accentPrimary
        let premiumMentions = premiumMentionTexts()

        guard !premiumMentions.isEmpty, let attributedText = textView.attributedText else {
            textView.linkTextAttributes = defaultLinkTextAttributes ?? [.foregroundColor: defaultLinkColor]
            return
        }

        textView.linkTextAttributes = [:]

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            guard value != nil else { return }
            mutable.addAttribute(.foregroundColor, value: defaultLinkColor, range: range)
        }

        let string = mutable.string
        for mention in premiumMentions {
            var searchStart = string.startIndex
            while let range = string.range(
                of: mention,
                options: [.caseInsensitive],
                range: searchStart..<string.endIndex
            ) {
                mutable.addAttribute(
                    .foregroundColor,
                    value: Self.premiumBorderColor,
                    range: NSRange(range, in: string)
                )
                searchStart = range.upperBound
            }
        }

        textView.attributedText = mutable
    }

    private func premiumMentionTexts() -> [String] {
        guard AppConfig.shared.demoAppConfig.shouldShowPremiumBadge,
              let message = content else { return [] }

        return message.mentionedUsers.compactMap { user in
            guard message.mentionedChannelMembers[user.id]?.isPremium == true else {
                return nil
            }
            return "@\(user.name ?? user.id)"
        }
    }
}

private extension ChatMessage.MemberInfo {
    var isPremium: Bool {
        extraData["is_premium"]?.boolValue == true
    }
}
