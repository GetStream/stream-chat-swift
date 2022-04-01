//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
open class ChatPresenceAvatarView: _View, ComponentsProvider {
    /// A view that shows the avatar image
    open private(set) lazy var avatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    /// A view indicating whether the user this view represents is online.
    ///
    /// The type of `onlineIndicatorView` is UIView & MaskProviding in Components.
    open private(set) lazy var onlineIndicatorView: UIView = components
        .onlineIndicatorView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Bool to determine if the indicator should be shown.
    open var isOnlineIndicatorVisible: Bool = false {
        didSet {
            onlineIndicatorView.isVisible = isOnlineIndicatorVisible
            setUpMask(indicatorVisible: isOnlineIndicatorVisible)
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        onlineIndicatorView.isHidden = true
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(avatarView)
        // Add online indicator view
        addSubview(onlineIndicatorView)
        
        onlineIndicatorView.topAnchor
            .pin(equalTo: topAnchor, constant: 1)
            .isActive = true
        onlineIndicatorView.rightAnchor
            .pin(equalTo: rightAnchor, constant: -1)
            .isActive = true
        onlineIndicatorView.widthAnchor
            .pin(equalTo: widthAnchor, multiplier: 0.2)
            .isActive = true
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        setUpMask(indicatorVisible: isOnlineIndicatorVisible)
    }
    
    /// Creates space for indicator view in avatar view by masking path provided by the indicator view.
    /// - Parameter visible: Bool to determine if the indicator should be shown. The avatar view won't be masked if the indicator is not visible.
    open func setUpMask(indicatorVisible: Bool) {
        guard
            indicatorVisible,
            let path = (onlineIndicatorView as? MaskProviding)?.maskingPath?.mutableCopy()
        else { return avatarView.layer.mask = nil }
        
        path.addRect(bounds)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd

        avatarView.layer.mask = maskLayer
    }
}
