//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatOnlineIndicatorView = _ChatOnlineIndicatorView<NoExtraData>

open class _ChatOnlineIndicatorView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        heightAnchor.pin(equalTo: widthAnchor).isActive = true
    }

    // MARK: - Lifecycle

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.frame = layer.frame.inset(by: .init(top: -1, left: -1, bottom: -1, right: -1))
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = (bounds.width / 5)
        layer.masksToBounds = true
        layer.backgroundColor = uiConfig.colorPalette.channelListAvatarOnlineIndicator.cgColor
        layer.borderColor = uiConfig.colorPalette.channelListIndicatorBorderColor.cgColor

        // Create a circle shape layer with true bounds.
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(ovalIn: bounds.inset(by: .init(top: -1, left: -1, bottom: -1, right: -1))).cgPath

        layer.mask = mask
    }
}
