//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for shrinking the input view to allow more space for other actions.
open class ShrinkInputButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let rightArrowIcon = appearance.images.shrinkInputArrow
        setImage(rightArrowIcon, for: .normal)
    }
}
