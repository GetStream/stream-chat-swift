//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

        configureUI()

        // create an instance of ChatClient and share it using the singleton
        let environment = ChatClient.Environment()
        client = ChatClient(config: config, environment: environment)
    }
    
    func configureUI() {
        // Customization
        var components = Components.default
        components.channelListRouter = CustomChannelListRouter.self
        components.messageListRouter = CustomMessageListRouter.self
        components.channelVC = ChannelVC.self
        components.threadVC = ThreadVC.self
        Components.default = components
        Components.default.messageActionsVC = MessageActionsVC.self
    }
    
}
