//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class PillButton: _Button, AppearanceProvider {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? appearance.colorPalette.highlightedBackground
                : appearance.colorPalette.staticColorText
        }
    }

    // MARK: - Lifecycle

    override open func setUpAppearance() {
        super.setUpAppearance()

        tintColor = appearance.colorPalette.staticBlackColorText
        setTitleColor(appearance.colorPalette.staticBlackColorText, for: .normal)
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

    // MARK: - Interaction

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
