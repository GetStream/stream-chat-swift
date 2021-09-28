//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class iMessageChatChannelHeaderView: ChatChannelHeaderView {
    lazy var avatarView = ChatChannelAvatarView()

    override func setUpAppearance() {
        super.setUpAppearance()

        titleContainerView.titleLabel.font = .systemFont(ofSize: 10)
        titleContainerView.titleLabel.textColor = .black
    }

    override func setUpLayout() {
        super.setUpLayout()

        titleContainerView.subtitleLabel.removeFromSuperview()
        titleContainerView.containerView.insertArrangedSubview(avatarView, at: 0)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 25),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor)
        ])
    }

    override func updateContent() {
        super.updateContent()

        avatarView.content = (channel: channelController?.channel, currentUserId: currentUserId)
    }
}
