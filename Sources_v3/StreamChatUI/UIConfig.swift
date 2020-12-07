//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct UIConfig<ExtraData: UIExtraDataTypes> {
    public var channelList = ChannelListUI()
    public var messageList = MessageListUI()
    public var messageComposer = MessageComposer()
    public var currentUser = CurrentUserUI()
    public var navigation = Navigation()
    public var colorPalette = ColorPalette()
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

// MARK: - Color Palette

public extension UIConfig {
    struct ColorPalette {
        public var highlightedColorForColor: (UIColor) -> UIColor = { $0.withAlphaComponent(0.5) }
        public var disabledColorForColor: (UIColor) -> UIColor = { _ in .lightGray }
        public var unselectedColorForColor: (UIColor) -> UIColor = { _ in .lightGray }

        public var outgoingMessageBubbleBackground: UIColor = UIColor(rgb: 0xe5e5e5)
        public var outgoingMessageBubbleBorder: UIColor = UIColor(rgb: 0xe5e5e5)
        public var incomingMessageBubbleBackground: UIColor = .white
        public var incomingMessageBubbleBorder: UIColor = UIColor(rgb: 0xe5e5e5)

        public var messageComposerBorder: UIColor = .streamGrayGainsboro
        public var messageComposerBackground: UIColor = .white
        public var messageComposerButton: UIColor = .streamGray
        public var messageComposerStateIcon: UIColor = .streamGrayGainsboro

        public var generalBackground: UIColor = UIColor(rgb: 0xfcfcfc)
        public var popupDimmedBackground: UIColor = UIColor.black.withAlphaComponent(0.2)
        public var galleryMoreImagesOverlayBackground: UIColor = UIColor.black.withAlphaComponent(0.4)
        public var messageTimestampText: UIColor = .lightGray
        public var subtitleText: UIColor = .lightGray
        public var unreadChatTint: UIColor = .systemGray
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
        public var imageGallery: ChatMessageImageGallery<ExtraData>.Type = ChatMessageImageGallery<ExtraData>.self
        public var imageGalleryItem: ChatMessageImageGallery<ExtraData>.ImagePreview.Type =
            ChatMessageImageGallery<ExtraData>.ImagePreview.self
        public var imageGalleryInteritemSpacing: CGFloat = 2
        public var onlyVisibleForCurrentUserIndicator: ChatMessageOnlyVisibleForCurrentUserIndicator.Type =
            ChatMessageOnlyVisibleForCurrentUserIndicator.self
        public var threadArrowView: ChatMessageThreadArrowView.Type = ChatMessageThreadArrowView.self
        public var threadInfoView: ChatMessageThreadInfoView<ExtraData>.Type = ChatMessageThreadInfoView<ExtraData>.self
    }
}

// MARK: - MessageComposer

public extension UIConfig {
    struct MessageComposer {
        public var messageComposerView: ChatChannelMessageComposerView<ExtraData>.Type =
            ChatChannelMessageComposerView<ExtraData>.self
        public var messageInputView: ChatChannelMessageInputView<ExtraData>.Type = ChatChannelMessageInputView<ExtraData>.self
        public var attachmentsView: MessageComposerAttachmentsView<ExtraData>.Type = MessageComposerAttachmentsView<ExtraData>.self
        public var sendButton: MessageComposerSendButton<ExtraData>.Type = MessageComposerSendButton<ExtraData>.self
        public var composerButton: ChatSquareButton<ExtraData>.Type = ChatSquareButton<ExtraData>.self
        public var textView: ChatChannelMessageInputTextView.Type = ChatChannelMessageInputTextView.self
    }
}

// MARK: - Steam constants

private extension UIColor {
    /// This is color palette used by design team.
    /// It's not fully used in figma yet, but we should stick with this colors if possible.
    static let streamBlack = UIColor(rgb: 0x000000)
    static let streamGray = UIColor(rgb: 0x7a7a7a)
    static let streamGrayGainsboro = UIColor(rgb: 0xdbdbdb)
    static let streamGrayWhisper = UIColor(rgb: 0xecebeb)
    static let streamWhiteSmoke = UIColor(rgb: 0xf2f2f2)
    static let streamWhiteSnow = UIColor(rgb: 0xfcfcfc)
    static let streamWhite = UIColor(rgb: 0xffffff)
    static let streamAccentBlue = UIColor(rgb: 0x005fff)
    static let streamAccentRed = UIColor(rgb: 0xff3742)
    static let streamAccentGreen = UIColor(rgb: 0x20e070)
}
