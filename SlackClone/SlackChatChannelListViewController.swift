//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

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
    
    override func setUp() {
        super.setUp()
        
        createNewChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
    }
    
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
        
        let createNewChannelView = UIView()
        createNewChannelView.backgroundColor = Colors.primary
        createNewChannelView.layer.masksToBounds = true
        createNewChannelView.layer.cornerRadius = 30
        createNewChannelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createNewChannelView)
        NSLayoutConstraint.activate([
            createNewChannelView.heightAnchor.constraint(equalToConstant: 60),
            createNewChannelView.widthAnchor.constraint(equalTo: createNewChannelView.heightAnchor),
            createNewChannelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            createNewChannelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])

        createNewChannelButton.translatesAutoresizingMaskIntoConstraints = false
        createNewChannelView.addSubview(createNewChannelButton)
        NSLayoutConstraint.activate([
            createNewChannelButton.topAnchor.constraint(equalTo: createNewChannelView.topAnchor, constant: 5),
            createNewChannelButton.bottomAnchor.constraint(equalTo: createNewChannelView.bottomAnchor, constant: -5),
            createNewChannelButton.leadingAnchor.constraint(equalTo: createNewChannelView.leadingAnchor, constant: 5),
            createNewChannelButton.trailingAnchor.constraint(equalTo: createNewChannelView.trailingAnchor, constant: -5)
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
