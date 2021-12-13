//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// The date separator view that groups messages from the same day.
open class ChatMessageListDateSeparatorView: _View, AppearanceProvider {
    /// The date in string format.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    /// The text label that renders the date string.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(textLabel, insets: NSDirectionalEdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9))
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background7

        textLabel.font = appearance.fonts.footnote
        textLabel.textColor = appearance.colorPalette.staticColorText
    }

    override open func updateContent() {
        super.updateContent()

        textLabel.text = content
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }
}
