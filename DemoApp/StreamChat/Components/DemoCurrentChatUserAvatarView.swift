//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class DemoCurrentChatUserAvatarView: CurrentChatUserAvatarView {
    override func setUpLayout() {
        super.setUpLayout()

        // A navigation bar gives its items a width of its own, which this view's aspect ratio does
        // not survive, and the avatar is then drawn as an oval. Keeping the avatar square and
        // centred leaves it a circle whatever width the view ends up with.
        avatarView.removeFromSuperview()
        addSubview(avatarView)

        let height = avatarView.heightAnchor.constraint(equalTo: heightAnchor)
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
            avatarView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
            avatarView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            height
        ])
    }
}
