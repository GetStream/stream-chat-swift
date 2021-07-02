//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    
    /// The channel name that we want to use for the livestream chat
    static let livestreamChannelName = "ytlivestream"
    
    /// The singleton instance of `ChatClient`
    static let shared: ChatClient = {
        
        var components = Components()

        components.messageListVC = YTLiveChatViewController.self
        components.messageComposerVC = YTChatComposerViewController.self
        components.messageComposerView = YTChatMessageComposerView.self
        components.scrollToLatestMessageButton = YTScrollToLatestMessageButton.self
        components.sendButton = YTSendButton.self
        components.inputMessageView = YTInputChatMessageView.self
        
        components.messageLayoutOptionsResolver = YTMessageLayoutOptionsResolver()

        Components.default = components

        let config = ChatClientConfig(apiKey: APIKey("bmrrcjf5bhzt"))
        
        let chatClient = ChatClient(
            config: config,
            tokenProvider: .development(userId: "sagar"))
        return chatClient
    }()
}

extension ChatChannelController {
    static var liveStreamChannelController: ChatChannelController {
        return ChatClient.shared.channelController(
            for: ChannelId(
                type: .livestream,
                id: ChatClient.livestreamChannelName
            ))
    }
}
