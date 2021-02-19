//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view used to indicate the presence of a user.
internal typealias ChatOnlineIndicatorView = _ChatOnlineIndicatorView<NoExtraData>

/// A view used to indicate the presence of a user.
internal class _ChatOnlineIndicatorView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    override internal func defaultAppearance() {
        super.defaultAppearance()

        backgroundColor = uiConfig.colorPalette.alternativeActiveTint
        layer.borderColor = uiConfig.colorPalette.lightBorder.cgColor
    }

    override internal func setUpLayout() {
        super.setUpLayout()
        heightAnchor.pin(equalTo: widthAnchor).isActive = true
    }

    override internal func layoutSubviews() {
        super.layoutSubviews()
        layer.frame = layer.frame.inset(by: .init(top: -1, left: -1, bottom: -1, right: -1))
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = (bounds.width / 5)
        layer.masksToBounds = true

        // Create a circle shape layer with true bounds.
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(ovalIn: bounds.inset(by: .init(top: -1, left: -1, bottom: -1, right: -1))).cgPath
        layer.mask = mask
    }
}
