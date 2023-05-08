//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A component used to show the (un)locked state of the recording flow.
open class LockIndicatorView: _View, ThemeProvider {
    public var content: Bool = false {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    open lazy var horizontalStackView: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var lockViewContainer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var container: UIView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var stackView: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var lockImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var chevronImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var bottomPaddingSpacer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var bottomPaddingConstraint: NSLayoutConstraint = bottomPaddingSpacer
        .heightAnchor
        .pin(equalToConstant: minimumBottomPadding)

    // MARK: - Configuration Properties

    /// The padding to add at the bottom when the content is `false`
    open var minimumBottomPadding: CGFloat = 4

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()
        container.clipsToBounds = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(horizontalStackView, insets: .init(top: 0, leading: 4, bottom: 0, trailing: 4))
        horizontalStackView.addArrangedSubview(.spacer(axis: .horizontal).withoutAutoresizingMaskConstraints)
        horizontalStackView.addArrangedSubview(lockViewContainer)

        lockViewContainer.axis = .vertical
        lockViewContainer.addArrangedSubview(container)
        lockViewContainer.addArrangedSubview(bottomPaddingSpacer)

        container.embed(stackView, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.addArrangedSubview(lockImageView)
        stackView.addArrangedSubview(chevronImageView)

        bottomPaddingConstraint.isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.border

        lockImageView.image = appearance.images.lock
        chevronImageView.image = appearance.images.chevronUp

        lockImageView.tintColor = content ? appearance.colorPalette.accentPrimary : appearance.colorPalette.textLowEmphasis
        chevronImageView.tintColor = lockImageView.tintColor
    }

    override open func updateContent() {
        super.updateContent()

        lockImageView.tintColor = content
            ? appearance.colorPalette.accentPrimary
            : appearance.colorPalette.textLowEmphasis

        chevronImageView.isHidden = content
        chevronImageView.alpha = chevronImageView.isHidden ? 0 : 1
        chevronImageView.tintColor = lockImageView.tintColor

        bottomPaddingConstraint.constant = content
            ? minimumBottomPadding
            : bottomPaddingConstraint.constant
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        container.layer.cornerRadius = container.bounds.width / 2.0
    }
}
