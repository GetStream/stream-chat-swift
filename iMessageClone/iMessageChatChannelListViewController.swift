//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatChannelListViewController: ChatChannelListVC {
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

    override func setUpAppearance() {
        super.setUpAppearance()
        
        title = "Messages"
        
        userAvatarView.isHidden = true
        navigationItem.searchController = UISearchController()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        
        view.directionalLayoutMargins.leading = 24
    }

    lazy var createChannelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "square.and.pencil")!, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createChannelButton)
        createChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
    }

    @objc func didTapCreateNewChannel(_ sender: Any) {
        // TODO: Implement
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    @objc
    private func editButtonTapped() {}
}
