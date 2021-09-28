//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class SlackChatChannelListItemView: ChatChannelListItemView {
    override func setUpAppearance() {
        super.setUpAppearance()
        avatarView.layer.cornerRadius = 4
    }

    override func setUpLayout() {
        super.setUpLayout()

        // Switch unreadCount and timestamp
        topContainer.addArrangedSubview(timestampLabel)
        bottomContainer.addArrangedSubview(unreadCountView)

        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 35),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
        ])
    }
}
