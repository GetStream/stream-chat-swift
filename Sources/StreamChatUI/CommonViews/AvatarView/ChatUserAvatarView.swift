//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    /// A boolean value to determine if online indicator should be shown or not.
    public var shouldShowOnlineIndicator: Bool = true

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)

        if !shouldShowOnlineIndicator {
            presenceAvatarView.onlineIndicatorView.isHidden = true
        }
    }

    override open func updateContent() {
        components.imageLoader.loadImage(
            into: presenceAvatarView.avatarView.imageView,
            from: content?.imageURL,
            with: ImageLoaderOptions(
                resize: .init(components.avatarThumbnailSize),
                placeholder: appearance.images.userAvatarPlaceholder1
            )
        )

        if shouldShowOnlineIndicator {
            presenceAvatarView.isOnlineIndicatorVisible = content?.isOnline ?? false
        }
    }
}
