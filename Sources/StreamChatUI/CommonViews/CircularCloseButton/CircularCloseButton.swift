//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for closing, dismissing or clearing information.
open class CircularCloseButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let closeIcon = appearance.images.closeCircleTransparent.tinted(with: appearance.colorPalette.inactiveTint)
        setImage(closeIcon, for: .normal)
    }
}
