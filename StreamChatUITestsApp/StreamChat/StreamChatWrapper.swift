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

        let config = ChatClientConfig(apiKey: .init(apiKey))

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
        let channelList = ChatChannelListVC.make(with: controller)
        return channelList
    }

}
