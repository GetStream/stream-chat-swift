//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class SlackChatChannelHeaderView: ChatChannelHeaderView {
    lazy var onlineIndicator = UIView()

    override func setUpAppearance() {
        super.setUpAppearance()

        onlineIndicator.layer.masksToBounds = true
        onlineIndicator.layer.cornerRadius = 5
        onlineIndicator.backgroundColor = Colors.green

        titleContainerView.titleLabel.font = appearance.fonts.bodyBold
        titleContainerView.subtitleLabel.font = appearance.fonts.footnote
    }

    override func setUpLayout() {
        super.setUpLayout()

        onlineIndicator.translatesAutoresizingMaskIntoConstraints = false
        titleContainerView.addSubview(onlineIndicator)
        NSLayoutConstraint.activate([
            onlineIndicator.heightAnchor.constraint(equalToConstant: 10),
            onlineIndicator.widthAnchor.constraint(equalTo: onlineIndicator.heightAnchor),
            onlineIndicator.trailingAnchor.constraint(equalTo: titleContainerView.leadingAnchor, constant: -4),
            onlineIndicator.centerYAnchor.constraint(equalTo: titleContainerView.centerYAnchor)
        ])
    }

    override func updateContent() {
        super.updateContent()

        let firstOtherMember = channelController?.channel?.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .first(where: { $0.id != currentUserId })

        onlineIndicator.isHidden = !(firstOtherMember?.isOnline ?? false)
    }

    override var subtitleText: String? {
        "View details"
    }
}
