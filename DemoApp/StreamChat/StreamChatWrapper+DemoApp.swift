//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

extension StreamChatWrapper {
    // Instantiates chat client
    func setUpChat() {
        guard client == nil else {
            log.error("Client was already instantiated")
            return
        }

        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        // Create Client
        client = ChatClient(config: config)

        // L10N
        let localizationProvider = Appearance.default.localizationProvider
        Appearance.default.localizationProvider = { key, table in
            let localizedString = localizationProvider(key, table)

            return localizedString == key
                ? Bundle.main.localizedString(forKey: key, value: nil, table: table)
                : localizedString
        }
    }

    func configureUI() {
        // Customize UI configuration
        Components.default.messageListDateSeparatorEnabled = true
        Components.default.messageListDateOverlayEnabled = true
        Components.default.isVoiceRecordingEnabled = true
        Components.default.isJumpToUnreadEnabled = true
        Components.default.messageSwipeToReplyEnabled = true
        Components.default.channelListSearchStrategy = .messages

        // Customize UI components
        Components.default.channelContentView = DemoChatChannelListItemView.self
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = DemoChatChannelVC.self
        Components.default.messageContentView = DemoChatMessageContentView.self
        Components.default.messageActionsVC = DemoChatMessageActionsVC.self
        Components.default.reactionsSorting = { $0.type.position < $1.type.position }
        Components.default.messageLayoutOptionsResolver = DemoChatMessageLayoutOptionsResolver()
    }
}
