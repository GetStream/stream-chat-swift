//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The date separator view that groups messages from the same day.
open class ChatMessageListDateSeparatorView: ChatMessageDecorationView, AppearanceProvider {
    /// The date in string format.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    /// The container that the contentTextLabel will be placed aligned to its centre.
    open private(set) lazy var container: UIView = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "dateSeparatorContainer")

    /// The text label that renders the date string.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "textLabel")

    override open func setUpLayout() {
        super.setUpLayout()

        addSubview(container)

        container.embed(textLabel, insets: .init(top: 3, leading: 9, bottom: 3, trailing: 9))

        NSLayoutConstraint.activate([
            container.leadingAnchor.pin(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.pin(lessThanOrEqualTo: trailingAnchor),
            container.topAnchor.pin(equalTo: topAnchor),
            container.bottomAnchor.pin(equalTo: bottomAnchor),
            container.centerXAnchor.pin(equalTo: centerXAnchor)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.background7

        textLabel.font = appearance.fonts.footnote
        textLabel.textColor = appearance.colorPalette.staticColorText
    }

    override open func updateContent() {
        super.updateContent()

        textLabel.text = content
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        container.layer.cornerRadius = bounds.height / 2
    }
}
