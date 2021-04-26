//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias MessageBubbleView = _MessageBubbleView<NoExtraData>

open class _MessageBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    open var roundedCorners: CACornerMask = .all {
        didSet { updateContentIfNeeded() }
    }

    open var cornerRadius: CGFloat { 16 }

    open var borderWidth: CGFloat { 1 }

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.borderWidth = borderWidth
        layer.borderColor = uiConfig.colorPalette.border.cgColor
        layer.cornerRadius = cornerRadius
    }

    override open func updateContent() {
        super.updateContent()

        layer.maskedCorners = roundedCorners
    }
}
