//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for shrinking the input view to allow more space for other actions.
open class ChatShrinkInputButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let rightArrowIcon = appearance.images.messageComposerShrinkInput
        setImage(rightArrowIcon, for: .normal)
    }
}
