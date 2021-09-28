//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class CustomActionsVC: ChatMessageActionsVC {
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        actions.removeAll { $0 is ThreadReplyActionItem }
        return actions
    }
}

final class SlackChatChannelListViewController: ChatChannelListVC {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let channelListController = ChatClient
            .shared
            .channelListController(
                query: ChannelListQuery(
                    filter: .containMembers(
                        userIds: [ChatClient.shared.currentUserId!]
                    )
                )
            )
        controller = channelListController
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    /// The `UIButton` instance used for navigating to new channel screen creation,
    lazy var createChannelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "new_message")!, for: .normal)
        return button
    }()

    override func setUpAppearance() {
        super.setUpAppearance()
        
        navigationItem.rightBarButtonItem = nil
    }
    
    override func setUpLayout() {
        let titleView = UIView()
        titleView.backgroundColor = Colors.primary
        titleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = "Direct Messages"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            titleLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -15)
        ])
        
        collectionView.contentInset.top = 50
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let jumpView = JumpView()
        jumpView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(jumpView)
        NSLayoutConstraint.activate([
            jumpView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            jumpView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            jumpView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 10)
        ])
        
        let createChannelView = UIView()
        createChannelView.backgroundColor = Colors.primary
        createChannelView.layer.masksToBounds = true
        createChannelView.layer.cornerRadius = 30
        createChannelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createChannelView)
        NSLayoutConstraint.activate([
            createChannelView.heightAnchor.constraint(equalToConstant: 60),
            createChannelView.widthAnchor.constraint(equalTo: createChannelView.heightAnchor),
            createChannelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            createChannelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])

        createChannelButton.translatesAutoresizingMaskIntoConstraints = false
        createChannelView.addSubview(createChannelButton)
        NSLayoutConstraint.activate([
            createChannelButton.topAnchor.constraint(equalTo: createChannelView.topAnchor, constant: 5),
            createChannelButton.bottomAnchor.constraint(equalTo: createChannelView.bottomAnchor, constant: -5),
            createChannelButton.leadingAnchor.constraint(equalTo: createChannelView.leadingAnchor, constant: 5),
            createChannelButton.trailingAnchor.constraint(equalTo: createChannelView.trailingAnchor, constant: -5)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
