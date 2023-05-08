//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A component used to guide the user on how to cancel an active recording flow.
open class SlideToCancelView: _View, ThemeProvider {
    public struct Content: Equatable {
        /// The title to show
        public var title: String

        /// The view's alpha
        public var alpha: CGFloat

        public init(title: String, alpha: CGFloat) {
            self.title = title
            self.alpha = alpha
        }
    }

    public var content: Content = .init(title: L10n.Recording.slideToCancel, alpha: 1) {
        didSet { updateContentIfNeeded() }
    }

    open lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

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
    }

    override open func updateContent() {
        super.updateContent()
        titleLabel.text = content.title
        alpha = content.alpha
    }
}
