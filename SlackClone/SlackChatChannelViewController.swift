//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatChannelViewController: ChatMessageListVC {
    private lazy var onlineIndicator = UIView()
    private lazy var titleLabel = UILabel()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()
        
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.alignment = .center
        titleStackView.spacing = 2
        
        let nameStackView = UIStackView()
        nameStackView.spacing = 3
        nameStackView.axis = .horizontal
        nameStackView.alignment = .center
        titleStackView.addArrangedSubview(nameStackView)

        onlineIndicator.layer.masksToBounds = true
        onlineIndicator.layer.cornerRadius = 5
        onlineIndicator.backgroundColor = Colors.green
        onlineIndicator.translatesAutoresizingMaskIntoConstraints = false
        nameStackView.addArrangedSubview(onlineIndicator)
        NSLayoutConstraint.activate([
            onlineIndicator.heightAnchor.constraint(equalToConstant: 10),
            onlineIndicator.widthAnchor.constraint(equalTo: onlineIndicator.heightAnchor)
        ])
        
        titleLabel.font = appearance.fonts.bodyBold
        nameStackView.addArrangedSubview(titleLabel)
        
        let detailsLabel = UILabel()
        detailsLabel.font = appearance.fonts.footnote
        detailsLabel.text = "View details"
        titleStackView.addArrangedSubview(detailsLabel)
        
        navigationItem.titleView = titleStackView
        navigationItem.rightBarButtonItem = nil
    }
    
    override func updateContent() {
        super.updateContent()
        
        guard let channel = channelController.channel else { return }
        
        titleLabel.text = DefaultChatChannelNamer()(channel, channelController.client.currentUserId)

        let firstOtherMember = channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .first(where: { $0.id != channelController.client.currentUserId })
        
        onlineIndicator.isHidden = !(firstOtherMember?.isOnline ?? false)
    }
    
    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        SlackChatMessageContentView.self
    }
}
