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
        var uiConfig = UIConfig()
        uiConfig.navigation.channelListRouter = SlackChatChannelListRouter.self
        uiConfig.avatarView = SlackChatAvatarView.self
        uiConfig.channelList.itemView = SlackChatChannelListItemView.self
        uiConfig.channelList.itemSubviews.unreadCountView = SlackChatChannelUnreadCountView.self
        uiConfig.images.newChat = UIImage(named: "new_message")!
        
        uiConfig.messageList.defaultMessageCell = SlackСhatMessageCollectionViewCell.self
        uiConfig.messageList.messageContentSubviews.authorAvatarView = SlackChatAvatarView.self
        uiConfig.messageList.messageContentSubviews.metadataView = SlackChatMessageMetadataView.self
        uiConfig.messageList.messageContentSubviews.attachmentSubviews.imageGallery = SlackChatMessageImageGallery.self
        
        UIConfig.default = uiConfig
        
        let config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        return ChatClient(
            config: config,
            tokenProvider: .static(
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2lsdmlhIn0.jHi2vjKoF02P9lOog0kDVhsIrGFjuWJqZelX5capR30"
            )
        )
    }()
}
