//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    /// The channel id used for the YT livestream demo chat.
    static let livestreamChannelId = ChannelId(
        type: .livestream,
        id: "ytlivestream"
    )

    /// The singleton instance of `ChatClient`
    @MainActor static let shared: ChatClient = {
        var components = Components()

        components.messageComposerVC = YTChatComposerViewController.self
        components.messageComposerView = YTChatMessageComposerView.self
        components.scrollToBottomButton = YTScrollToLatestMessageButton.self
        components.sendButton = YTSendButton.self
        components.inputMessageView = YTInputChatMessageView.self

        components.messageLayoutOptionsResolver = YTMessageLayoutOptionsResolver()

        Components.default = components

        let config = ChatClientConfig(apiKey: APIKey("bmrrcjf5bhzt"))

        let client = ChatClient(config: config)
        return client
    }()

    /// Creates a configured `LivestreamChat` for the YT livestream demo channel.
    @MainActor static func makeYTLivestreamChat() -> LivestreamChat {
        let livestreamChat = ChatClient.shared.makeLivestreamChat(for: ChatClient.livestreamChannelId)
        livestreamChat.maxMessageLimitOptions = .recommended
        livestreamChat.countSkippedMessagesWhenPaused = true
        return livestreamChat
    }
}
