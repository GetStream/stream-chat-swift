//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// A banner view that by default displays a text and button to perform an action.
open class BannerView: _View, ThemeProvider {
    /// Container which holds the elements on the banner.
    open private(set) lazy var container = UIStackView()
        .withoutAutoresizingMaskConstraints

    /// The text label describing the banner.
    open private(set) lazy var textLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    /// A spacer to make sure the label and the buttons are placed at the edges of the banner.
    open private(set) lazy var spacer = UIView.spacer(axis: .horizontal)

    /// A button that performs an action.
    open private(set) lazy var actionButton = UIButton()
        .withoutAutoresizingMaskConstraints

    /// The closure which is triggered whenever the action button is tapped.
    open var onAction: (() -> Void)?

    override open func setUp() {
        super.setUp()

        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.textLowEmphasis
        textLabel.textColor = appearance.colorPalette.staticColorText
        actionButton.tintColor = appearance.colorPalette.staticColorText
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        addSubview(container)
        container.pin(to: layoutMarginsGuide)
        container.axis = .horizontal
        container.alignment = .center
        [textLabel, spacer, actionButton].forEach {
            container.addArrangedSubview($0)
        }
    }

    @objc open func didTapActionButton() {
        onAction?()
    }
}
