//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
#if TESTS
@testable import StreamChat
#else
import StreamChat
#endif
import StreamChatUI

extension StreamChatWrapper {
    func setUpChat() {
        // Set the log level
        LogConfig.level = .debug
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        var config = ChatClientConfig(apiKey: .init(apiKeyString))
        config.isLocalStorageEnabled = settings.isLocalStorageEnabled.isOn
        config.staysConnectedInBackground = settings.staysConnectedInBackground.isOn

        // create an instance of ChatClient and share it using the singleton
        let environment = ChatClient.Environment()
        client = ChatClient(
            config: config,
            environment: environment,
            factory: .init(config: config, environment: environment)
        )
    }

    func configureUI() {
        // Customization
        Components.default.channelListRouter = CustomChannelListRouter.self
        Components.default.messageListRouter = CustomMessageListRouter.self
        Components.default.channelVC = ChannelVC.self
        Components.default.threadVC = ThreadVC.self
        Components.default.messageActionsVC = MessageActionsVC.self
        Components.default.messageContentView = MessageContentView.self
        Components.default.messageSwipeToReplyEnabled = true
        Components.default.isDraftMessagesEnabled = true
        Components.default.isBlockingUsersEnabled = true
        Components.default.isMessageEditedLabelEnabled = true

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("JUMP_TO_UNREAD_ENABLED") {
            Components.default.isJumpToUnreadEnabled = true
        }
        if arguments.contains("COMPOSER_LINK_PREVIEW") {
            Components.default.isComposerLinkPreviewEnabled = true
        }
        if arguments.contains("CHANNEL_LIST_STATES") {
            Components.default.isChatChannelListStatesEnabled = true
        }
        if arguments.contains("USE_CHANNEL_SEARCH") {
            Components.default.channelListSearchStrategy = .channels
        } else if arguments.contains("USE_MESSAGE_SEARCH") {
            Components.default.channelListSearchStrategy = .messages
        }
    }
}
