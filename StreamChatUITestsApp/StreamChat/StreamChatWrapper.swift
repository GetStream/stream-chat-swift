//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class StreamChatWrapper {

    var userCredentials: UserCredentials?

    func setupChatClient(with userCredentials: UserCredentials) {
        self.userCredentials = userCredentials

        var config = ChatClientConfig(apiKey: .init(apiKey))
        config.isLocalStorageEnabled = false

        /// create an instance of ChatClient and share it using the singleton
        ChatClient.shared = ChatClient(config: config)

        /// connect to chat
        ChatClient.shared.connectUser(
            userInfo: UserInfo(
                id: userCredentials.id,
                name: userCredentials.name,
                imageURL: userCredentials.avatarURL
            ),
            token: userCredentials.token
        )
    }

    func makeChannelListViewController() -> UIViewController {
        // UI
        let query = ChannelListQuery(filter: .containMembers(userIds: [userCredentials?.id ?? ""]))
        let controller = ChatClient.shared.channelListController(query: query)
        let channelList = ChannelList.make(with: controller)
        return channelList
    }

}

final class ChannelList: ChatChannelListVC, ChatConnectionControllerDelegate {
    private lazy var connectionController = controller.client.connectionController()
    
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
    }
}
