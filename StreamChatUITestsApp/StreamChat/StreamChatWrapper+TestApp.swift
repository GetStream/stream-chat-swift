//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        Components.default.messageSwipeToReplyEnabled = true
    }

}
