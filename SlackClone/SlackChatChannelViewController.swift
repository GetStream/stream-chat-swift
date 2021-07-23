//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatChannelViewController: ChatMessageListVC {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setUpLayout() {
        super.setUpLayout()

        navigationItem.rightBarButtonItem = nil
    }
    
    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        SlackChatMessageContentView.self
    }
}
