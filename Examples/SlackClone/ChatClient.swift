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

        components.messageLayoutOptionsResolver = SlackMessageOptionsResolver()
        components.messageListVC = SlackChatMessageListViewController.self
        components.channelVC = SlackChatChannelViewController.self
        components.channelHeaderView = SlackChatChannelHeaderView.self
        components.messageComposerVC = SlackComposerVC.self
        components.avatarView = SlackChatAvatarView.self
        components.channelContentView = SlackChatChannelListItemView.self
        components.channelUnreadCountView = SlackChatChannelUnreadCountView.self
        components.galleryView = SlackChatMessageGalleryView.self
        components.galleryAttachmentInjector = SlackGalleryAttachmentViewInjector.self
        components.messagePopupVC = SlackReactionsMessagePopupVC.self
        components.messageActionsTransitionController = SlackReactionsMessageActionsTransitionController.self

        Appearance.default = appearance
        Components.default = components

        var config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        config.isLocalStorageEnabled = true
        let client = ChatClient(
            config: config
        )
        return client
    }()
}
