//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
open class ChatUserAvatarView: _View, ThemeProvider {
    /// A view that shows the avatar image and online presence indicator.
    open private(set) lazy var presenceAvatarView: ChatPresenceAvatarView = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The data this view component shows.
    open var content: ChatUser? {
        didSet { updateContentIfNeeded() }
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
    }

    override open func updateContent() {
        if let url = content?.imageURL {
            presenceAvatarView.avatarView.imageView.loadImage(
                from: url,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
        } else {
            presenceAvatarView.avatarView.imageView.image = appearance.images.userAvatarPlaceholder1
        }
        presenceAvatarView.isOnlineIndicatorVisible = content?.isOnline ?? false
    }
}
