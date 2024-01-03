//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A component used to guide the user on how to cancel an active recording flow.
open class SlideToCancelView: _View, ThemeProvider {
    public struct Content: Equatable {
        /// The view's alpha
        public var alpha: CGFloat

        public init(alpha: CGFloat) {
            self.alpha = alpha
        }
    }

    public var content: Content = .init(alpha: 1) {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    /// The main container where all components will be added into.
    open lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    /// The label that displays the action message.
    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    /// An imageView showing a chevron image with the direction the slide needs to occur.
    open lazy var chevronImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(chevronImageView)
        chevronImageView.contentMode = .center

        container.axis = .horizontal
        container.spacing = 8

        addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.pin(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.pin(lessThanOrEqualTo: trailingAnchor),
            container.topAnchor.pin(equalTo: topAnchor),
            container.bottomAnchor.pin(equalTo: bottomAnchor),
            container.centerXAnchor.pin(equalTo: centerXAnchor),
            container.heightAnchor.pin(equalToConstant: 40)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        chevronImageView.image = appearance.images.chevronLeft.tinted(with: appearance.colorPalette.textLowEmphasis)
        titleLabel.textColor = appearance.colorPalette.textLowEmphasis
        titleLabel.font = appearance.fonts.body
        titleLabel.text = L10n.Recording.slideToCancel
    }

    override open func updateContent() {
        super.updateContent()
        alpha = content.alpha
    }
}
