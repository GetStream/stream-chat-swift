//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageBubbleView: _View, AppearanceProvider {
    open var roundedCorners: CACornerMask = .all {
        didSet { updateContentIfNeeded() }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.borderColor = appearance.colorPalette.border.cgColor
        layer.cornerRadius = 16
        layer.borderWidth = 1
    }

    override open func updateContent() {
        super.updateContent()

        layer.maskedCorners = roundedCorners
    }
}
