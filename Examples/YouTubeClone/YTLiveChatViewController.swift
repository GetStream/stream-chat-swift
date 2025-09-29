//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class YTLiveChatViewController: ChatChannelVC {
    override func setUp() {
        // The channel for live stream chat
        channelController = ChatChannelController.liveStreamChannelController
        super.setUp()
    }

    override func setUpAppearance() {
        super.setUpAppearance()

        navigationController?.isNavigationBarHidden = true
    }
}

final class YTLiveChatMessageListViewController: ChatMessageListVC {
    override func setUpLayout() {
        super.setUpLayout()
        NSLayoutConstraint.activate([
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            scrollToBottomButton.widthAnchor.constraint(equalToConstant: 30),
            scrollToBottomButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        dateOverlayView.removeFromSuperview()
    }

    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        YTChatMessageContentView.self
    }

    override func didSelectMessageCell(at indexPath: IndexPath) {}
}
