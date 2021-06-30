//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    /// The singleton instance of `ChatClient`
    static let shared: ChatClient = {
        // Register custom UI elements
        var appearance = Appearance()
        var components = Components()

        appearance.images.newChannel = UIImage(systemName: "square.and.pencil")!
        appearance.images.openAttachments = UIImage(systemName: "camera.fill")!
            .withTintColor(.systemBlue)

        components.channelContentView = iMessageChatChannelListItemView.self
        components.channelCellSeparator = iMessageCellSeparatorView.self

        components.messageListVC = iMessageChatChannelViewController.self
        components.messageComposerVC = iMessageComposerVC.self
        components.messageComposerView = iMessageComposerView.self
        components.messageLayoutOptionsResolver = iMessageChatMessageLayoutOptionsResolver()

        Appearance.default = appearance
        Components.default = components

        let config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        let client = ChatClient(config: config)
        
        client.connectUser(
            userInfo: UserInfo<NoExtraData>(id: "user-1"),
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2lsdmlhIn0.jHi2vjKoF02P9lOog0kDVhsIrGFjuWJqZelX5capR30"
        )
        return client
    }()
}
