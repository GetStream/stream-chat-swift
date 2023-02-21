//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

/// The date separator view that groups messages from the same day.
open class ChatThreadListRepliesCountSeparatorView: _View, AppearanceProvider {
    /// The date in string format.
    open var content: Int? {
        didSet { updateContentIfNeeded() }
    }

    open private(set) lazy var container: UIView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var separator: UIView = .init()
        .withoutAutoresizingMaskConstraints

    /// The text label that renders the date string.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "repliesCount")

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container, insets: NSDirectionalEdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))

        container.addSubview(separator)
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 9),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -9),
            separator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 9),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -9),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            textLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = nil

        separator.backgroundColor = appearance.colorPalette.border

        textLabel.backgroundColor = appearance.colorPalette.background
        textLabel.font = appearance.fonts.body
        textLabel.textColor = appearance.colorPalette.textLowEmphasis
    }

    override open func updateContent() {
        super.updateContent()

        if let content = content {
            textLabel.text = L10n.Message.Threads.count(content)
        } else {
            textLabel.text = L10n.Message.Threads.reply
        }
    }
}
