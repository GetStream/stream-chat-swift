//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that display text in a badge. Usually it is used for unread counts.
open class BadgeView: _View, ThemeProvider {
    /// The `UILabel` instance that displays the badge text.
    open private(set) lazy var textLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "textLabel")

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        layer.masksToBounds = true
        backgroundColor = appearance.colorPalette.alert

        textLabel.textColor = appearance.colorPalette.staticColorText
        textLabel.font = appearance.fonts.footnoteBold
        textLabel.textAlignment = .center
    }

    override open func setUpLayout() {
        layoutMargins = .init(top: 2, left: 3, bottom: 2, right: 3)

        addSubview(textLabel)
        textLabel.pin(to: layoutMarginsGuide)

        // The width shouldn't be smaller than height because we want to show it as a circle for small numbers
        widthAnchor.pin(greaterThanOrEqualTo: heightAnchor, multiplier: 1).isActive = true
    }
}
