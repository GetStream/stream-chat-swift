//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
internal typealias ChatUserAvatarView = _ChatUserAvatarView<NoExtraData>

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
internal class _ChatUserAvatarView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// A view that shows the avatar image and online presence indicator.
    internal private(set) lazy var presenceAvatarView: _ChatPresenceAvatarView<ExtraData> = uiConfig
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The data this view component shows.
    internal var content: _ChatUser<ExtraData.User>? {
        didSet { updateContentIfNeeded() }
    }

    override internal func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
    }

    override internal func updateContent() {
        if let url = content?.imageURL {
            presenceAvatarView.avatarView.imageView.loadImage(from: url)
        } else {
            presenceAvatarView.avatarView.imageView.image = uiConfig.images.userAvatarPlaceholder1
        }
        presenceAvatarView.onlineIndicatorView.isVisible = content?.isOnline ?? false
    }
}
