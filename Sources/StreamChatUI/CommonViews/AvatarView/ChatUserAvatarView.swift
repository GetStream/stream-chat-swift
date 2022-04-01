//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
open class ChatUserAvatarView: _View, ThemeProvider {
    /// Wether the avatar view should display the online indicator or not, even if the user is online.
    public var ignoreOnlinePresence = false

    /// Syntax sugar to easily configure the view without online presence.
    public var withIgnoringOnlinePresence: Self {
        let view = self
        view.ignoreOnlinePresence = true
        return view
    }

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
        components.imageLoader.loadImage(
            into: presenceAvatarView.avatarView.imageView,
            url: content?.imageURL,
            imageCDN: components.imageCDN,
            placeholder: appearance.images.userAvatarPlaceholder1,
            preferredSize: .avatarThumbnailSize
        )

        if !ignoreOnlinePresence {
            presenceAvatarView.isOnlineIndicatorVisible = content?.isOnline ?? false
        }
    }
}
