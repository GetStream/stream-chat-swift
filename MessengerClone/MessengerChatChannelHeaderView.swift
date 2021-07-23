//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class MessengerChatChannelHeaderView: ChatChannelHeaderView {
    lazy var avatarView = ChatChannelAvatarView()

    override func setUpAppearance() {
        super.setUpAppearance()

        titleContainerView.titleLabel.font = appearance.fonts.bodyBold
    }

    override func setUpLayout() {
        super.setUpLayout()

        titleContainerView.subtitleLabel.removeFromSuperview()

        titleContainerView.containerView.addArrangedSubview(avatarView)
        titleContainerView.containerView.addArrangedSubview(titleContainerView.titleLabel)
        titleContainerView.containerView.axis = .horizontal
        titleContainerView.containerView.spacing = 10

        let spacer = UIView()
        let constraint = spacer.widthAnchor.constraint(
            greaterThanOrEqualToConstant: .greatestFiniteMagnitude
        )
        constraint.isActive = true
        constraint.priority = .defaultLow
        titleContainerView.containerView.addArrangedSubview(spacer)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            avatarView.widthAnchor.constraint(equalToConstant: 32)
        ])
    }

    override func updateContent() {
        super.updateContent()

        avatarView.content = (channel: channelController?.channel, currentUserId: currentUserId)
    }
}
