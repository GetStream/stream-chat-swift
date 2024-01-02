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

        components.channelVC = MessengerChatChannelViewController.self
        components.channelHeaderView = MessengerChatChannelHeaderView.self

        components.channelContentView = ChatChannelListItemView.SwiftUIWrapper<MessengerChatChannelListItem>.self

        Appearance.default = appearance
        Components.default = components

        let config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        let client = ChatClient(config: config)
        return client
    }()
}
