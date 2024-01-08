//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A button that is being used in the VoiceRecording flow and represents a functionality on the playback.
/// - Note: As a MediaButton the appearance is common between light/dark mode.
open class MediaButton: _Button, AppearanceProvider {
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
