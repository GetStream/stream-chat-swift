//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows user avatar views stacked together.
open class StackedUserAvatarsView: _View, ThemeProvider {
    // MARK: - Content

    struct Content {
        var users: [ChatUser]
    }

    var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Configuration

    /// The maximum number of avatars.
    public var maximumNumberOfAvatars = 2

    // MARK: - Views

    /// The user avatar views.
    open lazy var userAvatarViews: [ChatUserAvatarView] = {
        (0...maximumNumberOfAvatars - 1).map { _ in
            let avatarView = components.userAvatarView.init()
                .width(20)
                .height(20)
            avatarView.shouldShowOnlineIndicator = false
            return avatarView
        }
    }()

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer(spacing: -4) {
            userAvatarViews
        }.embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        userAvatarViews.forEach {
            $0.isHidden = true
        }
        zip(userAvatarViews, content.users).forEach { avatarView, user in
            avatarView.content = user
            avatarView.isHidden = false
        }
    }
}
