//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for opening commands.
open class ChatCommandButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let boltIcon = appearance
            .images
            .messageComposerCommand
            .tinted(with: appearance.colorPalette.inactiveTint)
        setImage(boltIcon, for: .normal)
    }
}
