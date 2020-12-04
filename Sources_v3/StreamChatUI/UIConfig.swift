//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct UIConfig<ExtraData: UIExtraDataTypes> {
    public var channelList = ChannelListUI()
    public var messageList = MessageListUI()
    public var currentUser = CurrentUserUI()
    public var navigation = Navigation()
}

// MARK: - UIConfig + Default

private var defaults: [String: Any] = [:]

public extension UIConfig {
    static var `default`: Self {
        get {
            let key = String(describing: ExtraData.self)
            if let existing = defaults[key] as? Self {
                return existing
            } else {
                let config = Self()
                defaults[key] = config
                return config
            }
        }
        set {
            let key = String(describing: ExtraData.self)
            defaults[key] = newValue
        }
    }
}

// MARK: - Navigation

public extension UIConfig {
    struct Navigation {
        public var navigationBar: ChatNavigationBar.Type = ChatNavigationBar.self
        public var channelListRouter: ChatChannelListRouter<ExtraData>.Type = ChatChannelListRouter<ExtraData>.self
        public var channelDetailRouter: ChatChannelRouter<ExtraData>.Type = ChatChannelRouter<ExtraData>.self
    }
}

// MARK: - ChannelListUI

public extension UIConfig {
    struct ChannelListUI {
        public var channelCollectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self
        public var channelCollectionLayout: UICollectionViewLayout.Type = ChatChannelListCollectionViewLayout.self
        public var channelListItemView: ChatChannelListItemView<ExtraData>.Type = ChatChannelListItemView<ExtraData>.self
        public var channelViewCell: ChatChannelListCollectionViewCell<ExtraData>.Type =
            ChatChannelListCollectionViewCell<ExtraData>.self
        public var newChannelButton: CreateNewChannelButton.Type = CreateNewChannelButton.self
        public var channelListItemSubviews = ChannelListItemSubviews()
    }
    
    struct ChannelListItemSubviews {
        public var avatarView: ChatChannelAvatarView<ExtraData>.Type = ChatChannelAvatarView.self
        public var unreadCountView: ChatUnreadCountView.Type = ChatUnreadCountView.self
        public var readStatusView: ChatReadStatusCheckmarkView.Type = ChatReadStatusCheckmarkView.self
    }
}

// MARK: - CurrentUser

public extension UIConfig {
    struct CurrentUserUI {
        public var currentUserViewAvatarView: CurrentChatUserAvatarView<ExtraData>.Type = CurrentChatUserAvatarView<ExtraData>.self
        public var avatarView: AvatarView.Type = AvatarView.self
    }
}

// MARK: - MessageListUI

public extension UIConfig {
    struct MessageListUI {
        public var collectionView: ChatChannelCollectionView.Type = ChatChannelCollectionView.self
        public var collectionLayout: ChatChannelCollectionViewLayout.Type = ChatChannelCollectionViewLayout.self
        public var minTimeInvteralBetweenMessagesInGroup: TimeInterval = 10
        /// Vertical contentOffset for message list, when next message batch should be requested
        public var offsetToPreloadMoreMessages: CGFloat = 100
        public var messageContentView: ChatMessageContentView<ExtraData>.Type = ChatMessageContentView<ExtraData>.self
        public var messageContentSubviews = MessageContentViewSubviews()
        public var messageAvailableReactions: [MessageReactionType] = [
            .init(rawValue: "like"),
            .init(rawValue: "haha"),
            .init(rawValue: "facepalm"),
            .init(rawValue: "roar")
        ]
        public var messageActionsView: MessageActionsView<ExtraData>.Type =
            MessageActionsView<ExtraData>.self
        public var messageActionButton: MessageActionsView<ExtraData>.ActionButton.Type =
            MessageActionsView<ExtraData>.ActionButton.self
        public var messageReactionsView: ChatMessageReactionsView.Type = ChatMessageReactionsView.self
    }

    struct MessageContentViewSubviews {
        public var authorAvatarView: AvatarView.Type = AvatarView.self
        public var bubbleView: ChatMessageBubbleView<ExtraData>.Type = ChatMessageBubbleView<ExtraData>.self
        public var metadataView: ChatMessageMetadataView<ExtraData>.Type = ChatMessageMetadataView<ExtraData>.self
        public var repliedMessageContentView: ChatRepliedMessageContentView<ExtraData>.Type =
            ChatRepliedMessageContentView<ExtraData>.self
    }
}
