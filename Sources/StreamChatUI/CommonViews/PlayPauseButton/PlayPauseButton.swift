//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class PlayPauseButton: _Button, AppearanceProvider {
    open var sideConstant: CGFloat = 34 {
        didSet { heightConstraint.constant = sideConstant }
    }

    open private(set) lazy var heightConstraint: NSLayoutConstraint = heightAnchor
        .pin(equalToConstant: sideConstant)

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? appearance.colorPalette.highlightedBackground
                : appearance.colorPalette.staticColorText
        }
    }

    override open func setUp() {
        super.setUp()
        NSLayoutConstraint.activate([
            heightConstraint,
            widthAnchor.pin(equalTo: heightAnchor)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        setImage(appearance.images.playFill, for: .normal)
        setImage(appearance.images.pauseFill, for: .selected)

        tintColor = appearance.colorPalette.staticBlackColorText
        backgroundColor = appearance.colorPalette.staticColorText
        layer.shadowColor = tintColor.cgColor
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0, height: 2)
    }

    override open func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)
        isHighlighted = true
    }

    override open func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesEnded(touches, with: event)
        isHighlighted = false
    }

    override open func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesCancelled(touches, with: event)
        isHighlighted = false
    }
}
