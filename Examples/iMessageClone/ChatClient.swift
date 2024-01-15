//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

        appearance.images.openAttachments = UIImage(systemName: "camera.fill")!
            .withTintColor(.systemBlue)

        components.channelContentView = iMessageChatChannelListItemView.self
        components.channelCellSeparator = iMessageCellSeparatorView.self

        components.channelVC = iMessageChatChannelViewController.self
        components.messageListVC = iMessageChatMessageListViewController.self
        components.channelHeaderView = iMessageChatChannelHeaderView.self
        components.messageComposerVC = iMessageComposerVC.self
        components.messageComposerView = iMessageComposerView.self
        components.messageLayoutOptionsResolver = iMessageChatMessageLayoutOptionsResolver()

        Appearance.default = appearance
        Components.default = components

        let config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        let client = ChatClient(config: config)
        return client
    }()
}
