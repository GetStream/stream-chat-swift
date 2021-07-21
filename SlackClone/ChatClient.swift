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

        components.messageLayoutOptionsResolver = SlackMessageOptionsResolver()
        components.messageListVC = SlackChatChannelViewController.self
        components.messageListHeaderView = SlackChatChannelHeaderView.self
        components.messageComposerVC = SlackComposerVC.self
        components.avatarView = SlackChatAvatarView.self
        components.channelContentView = SlackChatChannelListItemView.self
        components.channelUnreadCountView = SlackChatChannelUnreadCountView.self
        components.galleryView = SlackChatMessageGalleryView.self
        
        Appearance.default = appearance
        Components.default = components
        
        let config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        let client = ChatClient(
            config: config
        )
        client.connectUser(
            userInfo: .init(id: "user-1"),
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2lsdmlhIn0.jHi2vjKoF02P9lOog0kDVhsIrGFjuWJqZelX5capR30"
        )
        return client
    }()
}
