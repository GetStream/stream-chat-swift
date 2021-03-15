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
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    @objc
    private func editButtonTapped() {}
}
