//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class ChannelList: ChatChannelListVC, ChatConnectionControllerDelegate {
    private lazy var connectionController = controller.client.connectionController()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (router as? CustomChannelListRouter)?.channelListWillAppear(self)
    }

    override func setUp() {
        super.setUp()

        connectionController.delegate = self
        updateTitle(with: connectionController.connectionStatus)
    }

    override func setUpAppearance() {
        super.setUpAppearance()

        updateTitle(with: connectionController.connectionStatus)
    }

    func connectionController(
        _ controller: ChatConnectionController,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        updateTitle(with: status)
    }

    private func updateTitle(with status: ConnectionStatus) {
        switch status {
        case .initialized:
            title = "initialized"
        case .connecting:
            title = "connecting"
        case .connected:
            title = "connected"
        case .disconnecting:
            title = "disconnecting"
        case .disconnected:
            title = "disconnected"
        }
        navigationItem.titleView?.accessibilityIdentifier = title
    }
}
