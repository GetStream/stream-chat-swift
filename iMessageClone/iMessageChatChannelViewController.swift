//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatChannelViewController: ChatMessageListVC {
    override func setUpLayout() {
        super.setUpLayout()

        navigationItem.rightBarButtonItem = nil
    }

    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        iMessageChatMessageContentView.self
    }
}
