//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatChannelViewController: ChatMessageListVC {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        guard let channel = channelController.channel else { return }
     
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.alignment = .center
        titleStackView.spacing = 3
        titleStackView.isLayoutMarginsRelativeArrangement = true
        
        let avatar = ChatChannelAvatarView()
        avatar.content = (channel: channel, currentUserId: channelController.client.currentUserId)
        avatar.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.addArrangedSubview(avatar)
        NSLayoutConstraint.activate([
            avatar.heightAnchor.constraint(equalToConstant: 25),
            avatar.widthAnchor.constraint(equalTo: avatar.heightAnchor)
        ])
        
        let titleLabel = UILabel()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .black
        titleLabel.text = DefaultChatChannelNamer()(channel, channelController.client.currentUserId) ?? ""
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleStackView.addArrangedSubview(titleLabel)
        
        navigationItem.titleView = titleStackView
        
        navigationItem.rightBarButtonItem = nil
    }

    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        iMessageChatMessageContentView.self
    }
}
