//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for closing, dismissing or clearing information.
open class ChatCloseButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let closeIcon = appearance.images.close1.tinted(with: appearance.colorPalette.inactiveTint)
        setImage(closeIcon, for: .normal)
    }
}
