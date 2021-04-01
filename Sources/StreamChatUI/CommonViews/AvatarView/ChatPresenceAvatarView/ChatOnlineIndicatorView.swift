//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol MaskProviding {
    /// Path used to mask space in super view.
    ///
    /// No mask is used when nil is returned
    var maskingPath: CGPath? { get }
}

/// A view used to indicate the presence of a user.
public typealias ChatOnlineIndicatorView = _ChatOnlineIndicatorView<NoExtraData>

/// A view used to indicate the presence of a user.
open class _ChatOnlineIndicatorView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider, MaskProviding {
    override public func defaultAppearance() {
        super.defaultAppearance()

        backgroundColor = uiConfig.colorPalette.alternativeActiveTint
    }

    override open func setUpLayout() {
        super.setUpLayout()
        heightAnchor.pin(equalTo: widthAnchor).isActive = true
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.width / 2
        layer.masksToBounds = true
    }
    
    open var maskingPath: CGPath? {
        UIBezierPath(ovalIn: frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)).cgPath
    }
}
