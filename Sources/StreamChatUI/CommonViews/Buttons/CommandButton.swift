//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import UIKit

/// Button for opening commands.
open class CommandButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let boltIcon = appearance
            .images
            .commands
            .tinted(with: appearance.colorPalette.inactiveTint)
        setImage(boltIcon, for: .normal)
    }
}
