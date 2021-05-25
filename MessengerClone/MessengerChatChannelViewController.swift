//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class MessengerChatChannelViewController: ChatMessageListVC {
    private lazy var titleLabel = UILabel()
    private lazy var avatar = ChatChannelAvatarView()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()
        
        let titleStackView = UIStackView()
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = 10

        avatar.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.addArrangedSubview(avatar)
        NSLayoutConstraint.activate([
            avatar.heightAnchor.constraint(equalToConstant: 32),
            avatar.widthAnchor.constraint(equalToConstant: 32)
        ])
        
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.font = appearance.fonts.bodyBold
        titleStackView.addArrangedSubview(titleLabel)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let widthAnchor = spacer.widthAnchor.constraint(equalToConstant: 1000)
        widthAnchor.priority = .defaultLow
        widthAnchor.isActive = true

        titleStackView.addArrangedSubview(spacer)
        
        navigationItem.titleView = titleStackView
        
        let callBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "phone.fill"),
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.rightBarButtonItem = callBarButtonItem
    }
    
    override func updateContent() {
        super.updateContent()
        
        guard let channel = channelController.channel else { return }
        
        titleLabel.text = DefaultChatChannelNamer()(channel, channelController.client.currentUserId)
        
        avatar.content = (channel: channel, currentUserId: channelController.client.currentUserId)
    }
}
