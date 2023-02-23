//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The date separator view that groups messages from the same day.
open class ChatThreadRepliesCountDecorationView: ChatMessageDecorationView, AppearanceProvider {
    /// The date in string format.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    /// The container that the contentTextLabel will be placed aligned to its centre.
    open private(set) lazy var container: UIView = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "repliesCountDecorationContainer")

    /// The text label that renders the date string.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "textLabel")

    open private(set) lazy var leadingHairline: UIView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var trailingHairline: UIView = .init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container)

        container.addSubview(leadingHairline)
        container.addSubview(textLabel)
        container.addSubview(trailingHairline)

        NSLayoutConstraint.activate([
            leadingHairline.heightAnchor.constraint(equalToConstant: 1),
            leadingHairline.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 9),
            leadingHairline.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            textLabel.leadingAnchor.constraint(equalTo: leadingHairline.trailingAnchor, constant: 9),
            textLabel.trailingAnchor.constraint(equalTo: trailingHairline.leadingAnchor, constant: -9),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            textLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            trailingHairline.heightAnchor.constraint(equalToConstant: 1),
            trailingHairline.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -9),
            trailingHairline.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = nil

        leadingHairline.backgroundColor = appearance.colorPalette.border
        trailingHairline.backgroundColor = appearance.colorPalette.border

        textLabel.font = appearance.fonts.body
        textLabel.textColor = appearance.colorPalette.textLowEmphasis
    }

    override open func updateContent() {
        super.updateContent()

        textLabel.text = content
    }
}
