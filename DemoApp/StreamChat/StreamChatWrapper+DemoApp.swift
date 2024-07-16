//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

extension StreamChatWrapper {
    // Instantiates chat client
    func setUpChat() {
        if AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled {
            Components.default.mixedAttachmentInjector.register(.location, with: LocationAttachmentViewInjector.self)
        }

        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        // Create Client
        if client == nil {
            client = ChatClient(config: config)
        }
        client?.registerAttachment(LocationAttachmentPayload.self)

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
        Components.default.messageAutoTranslationEnabled = true
        Components.default.isMessageEditedLabelEnabled = true
        Components.default.isVoiceRecordingEnabled = true
        Components.default.isJumpToUnreadEnabled = true
        Components.default.messageSwipeToReplyEnabled = true
        Components.default.isComposerLinkPreviewEnabled = true
        Components.default.channelListSearchStrategy = .messages

        // Customize UI components
        Components.default.attachmentViewCatalog = DemoAttachmentViewCatalog.self
        Components.default.messageListVC = DemoChatMessageListVC.self
        Components.default.quotedMessageView = DemoQuotedChatMessageView.self
        Components.default.messageComposerVC = DemoComposerVC.self
        Components.default.channelContentView = DemoChatChannelListItemView.self
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = DemoChatChannelVC.self
        Components.default.threadVC = DemoChatThreadVC.self
        Components.default.messageContentView = DemoChatMessageContentView.self
        Components.default.messageActionsVC = DemoChatMessageActionsVC.self
        Components.default.messageLayoutOptionsResolver = DemoChatMessageLayoutOptionsResolver()
        Components.default.reactionsSorting = ReactionSorting.byFirstReactionAt
        Components.default.channelListErrorView = DemoChatChannelListErrorView.self

        // Customize MarkdownFormatter
        let defaultFormatter = DefaultMarkdownFormatter()
        defaultFormatter.styles.bodyFont.color = .systemOrange
        defaultFormatter.styles.codeFont.color = .systemPurple
        defaultFormatter.styles.h1Font.color = .systemBlue
        defaultFormatter.styles.h2Font.color = .systemRed
        defaultFormatter.styles.h3Font.color = .systemYellow
        defaultFormatter.styles.h4Font.color = .systemGreen
        defaultFormatter.styles.h5Font.color = .systemBrown
        defaultFormatter.styles.h6Font.color = .systemPink
        Appearance.default.formatters.markdownFormatter = defaultFormatter
    }
}

/// Examples of some reactions sorting.
enum ReactionSorting {
    /// Sorting by score.
    static func byScore(_ lhs: ChatMessageReactionData, _ rhs: ChatMessageReactionData) -> Bool {
        lhs.score > rhs.score
    }

    /// Sorting by count.
    static func byCount(_ lhs: ChatMessageReactionData, _ rhs: ChatMessageReactionData) -> Bool {
        lhs.count > rhs.count
    }

    /// Sorting by firstReactionAt.
    static func byFirstReactionAt(_ lhs: ChatMessageReactionData, _ rhs: ChatMessageReactionData) -> Bool {
        guard let lhsFirstReactionAt = lhs.firstReactionAt, let rhsFirstReactionAt = rhs.firstReactionAt else {
            return false
        }

        return lhsFirstReactionAt < rhsFirstReactionAt
    }

    /// Sorting by firstReactionAt and count.
    static func byFirstReactionAtAndCount(_ lhs: ChatMessageReactionData, _ rhs: ChatMessageReactionData) -> Bool {
        if lhs.count == rhs.count {
            return ReactionSorting.byFirstReactionAt(lhs, rhs)
        }

        return lhs.count > rhs.count
    }
}
