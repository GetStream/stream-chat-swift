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
        uiConfig.channelList.itemView = iMessageChatChannelListItemView.self
        uiConfig.channelList.cellSeparatorReusableView = iMessageCellSeparatorView.self

        uiConfig.navigation.channelListRouter = iMessageChatChannelListRouter.self
        uiConfig.images.newChat = UIImage(systemName: "square.and.pencil")!
        uiConfig.messageComposer.messageComposerView = iMessageChatMessageComposerView.self
        uiConfig.messageList.messageContentView = iMessageChatMessageContentView.self
        uiConfig.messageList.defaultMessageCell = iMessageСhatMessageCollectionViewCell.self
        uiConfig.messageComposer.messageComposerViewController = iMessageChatComposerViewController.self

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
