//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
internal typealias ChatPresenceAvatarView = _ChatPresenceAvatarView<NoExtraData>

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
internal class _ChatPresenceAvatarView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// A view that shows the avatar image
    internal private(set) lazy var avatarView: ChatAvatarView = uiConfig
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    /// A view indicating whether the user this view represents is online.
    internal private(set) lazy var onlineIndicatorView: UIView = uiConfig
        .onlineIndicatorView.init()
        .withoutAutoresizingMaskConstraints

    override internal func defaultAppearance() {
        super.defaultAppearance()
        onlineIndicatorView.isHidden = true
    }

    override internal func setUpLayout() {
        super.setUpLayout()
        embed(avatarView)
        // Add online indicator view
        addSubview(onlineIndicatorView)
        onlineIndicatorView.pin(anchors: [.top, .right], to: self)
        onlineIndicatorView.widthAnchor
            .pin(equalTo: widthAnchor, multiplier: 0.3)
            .isActive = true
    }
}
