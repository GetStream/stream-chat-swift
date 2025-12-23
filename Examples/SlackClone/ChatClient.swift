//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
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
        components.reactionsSorting = ReactionSorting.byFirstReactionAtAndCount

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
