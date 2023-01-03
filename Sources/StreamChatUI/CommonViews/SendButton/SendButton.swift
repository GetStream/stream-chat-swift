//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used for sending a message, or any type of content.
open class SendButton: _Button, AppearanceProvider {
    /// Override this variable to enable custom behavior upon button enabled.
    override open var isEnabled: Bool {
        didSet {
            isEnabledChangeAnimation(isEnabled)
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        let normalStateImage = appearance.images.sendArrow
        setImage(normalStateImage, for: .normal)

        let buttonColor: UIColor = appearance.colorPalette.alternativeInactiveTint
        let disabledStateImage = appearance.images.sendArrow.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }

    /// The animation when the `isEnabled` state changes.
    open func isEnabledChangeAnimation(_ isEnabled: Bool) {
        Animate {
            self.transform = isEnabled
                ? CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
                : .identity
        }
    }
}
