//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class PlayPauseButton: _Button, AppearanceProvider {
    /// The size of each side of the button.
    /// - Note: Once set, height and width constraints will be updated and a re-layout will be triggered.
    open var sideConstant: CGFloat = 34 {
        didSet {
            heightConstraint.constant = sideConstant
            widthConstraint.constant = sideConstant
            setNeedsLayout()
        }
    }

    /// A reference to the height constraint.
    open private(set) lazy var heightConstraint: NSLayoutConstraint = heightAnchor
        .pin(equalToConstant: sideConstant)

    /// A reference to the width constraint.
    open private(set) lazy var widthConstraint: NSLayoutConstraint = widthAnchor
        .pin(equalToConstant: sideConstant)

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? appearance.colorPalette.highlightedBackground
                : appearance.colorPalette.staticColorText
        }
    }

    // MARK: - UI Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        heightConstraint.isActive = true
        widthConstraint.isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        setImage(appearance.images.playFill, for: .normal)
        setImage(appearance.images.pauseFill, for: .selected)

        tintColor = appearance.colorPalette.staticBlackColorText
        backgroundColor = isHighlighted
            ? appearance.colorPalette.highlightedBackground
            : appearance.colorPalette.staticColorText
        layer.shadowColor = tintColor.cgColor
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0, height: 2)
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isHighlighted = true
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        isHighlighted = false
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        isHighlighted = false
    }
}
