//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Protocol used to get path to make a cutout in a parent view.
///
/// This protocol is used to make a transparent "border" around online indicator in avatar view.
public protocol MaskProviding {
    /// Path used to mask space in super view.
    ///
    /// No mask is used when nil is returned
    var maskingPath: CGPath? { get }
}

/// A view used to indicate the presence of a user.
open class OnlineIndicatorView: _View, AppearanceProvider, MaskProviding {
    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.alternativeActiveTint
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
