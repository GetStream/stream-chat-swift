//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class BubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    var roundedCorners: CACornerMask = .all {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    private(set) lazy var borderLayer = CAShapeLayer()

    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
    }

    override func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        borderLayer.contentsScale = layer.contentsScale
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1
        
        borderLayer.borderColor = uiConfig.colorPalette.border.cgColor
    }

    override func setUp() {
        super.setUp()

        layer.addSublayer(borderLayer)
    }

    override func updateContent() {
        super.updateContent()

        borderLayer.maskedCorners = roundedCorners
        layer.maskedCorners = roundedCorners
    }
}

extension CACornerMask {
    static let all: Self = [
        .layerMinXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMaxXMinYCorner,
        .layerMaxXMaxYCorner
    ]
}
