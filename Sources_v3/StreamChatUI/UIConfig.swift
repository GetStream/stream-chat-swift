//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct UIConfig<ExtraData: ExtraDataTypes> {
    public var channelList = ChannelListUI()
    public var messageList = MessageListUI()
    public var messageComposer = MessageComposer()
    public var currentUser = CurrentUserUI()
    public var navigation = Navigation()
    public var colorPalette = ColorPalette()
    
    public init() {}
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
        // MARK: - General

        public var subtitleText: UIColor = .streamGray
        public var text: UIColor = .streamBlack
        public var generalBackground: UIColor = UIColor(rgb: 0xfcfcfc)
        public var shadow: UIColor = .streamGray

        // MARK: - Text interactions

        public var highlightedColorForColor: (UIColor) -> UIColor = { $0.withAlphaComponent(0.5) }
        public var disabledColorForColor: (UIColor) -> UIColor = { _ in .lightGray }
        public var unselectedColorForColor: (UIColor) -> UIColor = { _ in .lightGray }

        // MARK: - Message Bubbles

        public var outgoingMessageBubbleBackground: UIColor = .streamGrayGainsboro
        public var outgoingMessageBubbleBorder: UIColor = .streamGrayGainsboro
        public var incomingMessageBubbleBackground: UIColor = .streamWhite
        public var incomingMessageBubbleBorder: UIColor = .streamGrayGainsboro
        public var outgoingMessageInactiveReaction: UIColor = .streamGray
        public var incomingMessageInactiveReaction: UIColor = .streamGray

        // MARK: - Message Composer

        public var messageComposerBorder: UIColor = .streamGrayGainsboro
        public var messageComposerBackground: UIColor = .white
        public var messageComposerButton: UIColor = .streamGray
        public var messageComposerStateIcon: UIColor = .streamGrayGainsboro
        public var messageComposerPlaceholder: UIColor = .streamGray
        public var slashCommandViewBackground: UIColor = .streamAccentBlue
        public var slashCommandViewText: UIColor = .white

        // MARK: - Message interaction

        public var popupDimmedBackground: UIColor = UIColor.black.withAlphaComponent(0.2)
        public var galleryMoreImagesOverlayBackground: UIColor = UIColor.black.withAlphaComponent(0.4)
        public var messageTimestampText: UIColor = .lightGray
        public var unreadChatTint: UIColor = .systemGray
    }
}

// MARK: - Navigation

public extension UIConfig {
    struct Navigation {
        public var navigationBar: ChatNavigationBar.Type = ChatNavigationBar.self
        public var channelListRouter: ChatChannelListRouter<ExtraData>.Type = ChatChannelListRouter<ExtraData>.self
        public var messageListRouter: ChatMessageListRouter<ExtraData>.Type = ChatMessageListRouter<ExtraData>.self
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
        public var readStatusView: ChatReadStatusCheckmarkView<ExtraData>.Type = ChatReadStatusCheckmarkView<ExtraData>.self
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
        public var messageListVC: ChatMessageListVC<ExtraData>.Type = ChatMessageListVC<ExtraData>.self
        public var incomingMessageCell: СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatIncomingMessageCollectionViewCell<ExtraData>.self
        public var outgoingMessageCell: СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatOutgoingMessageCollectionViewCell<ExtraData>.self

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
            .init(rawValue: "thumbsup"),
            .init(rawValue: "thumbsdown"),
            .init(rawValue: "wut")
        ]

        public var smallIconForMessageReaction: (MessageReactionType) -> UIImage? = { reaction in
            switch reaction.rawValue {
            case "like": return UIImage(named: "reaction_love_small", in: .streamChatUI)
            case "haha": return UIImage(named: "reaction_lol_small", in: .streamChatUI)
            case "thumbsup": return UIImage(named: "reaction_thumbsup_small", in: .streamChatUI)
            case "thumbsdown": return UIImage(named: "reaction_thumbsdown_small", in: .streamChatUI)
            case "wut": return UIImage(named: "reaction_wut_small", in: .streamChatUI)
            default: return nil
            }
        }

        public var bigIconForMessageReaction: (MessageReactionType) -> UIImage? = { reaction in
            switch reaction.rawValue {
            case "like": return UIImage(named: "reaction_love_big", in: .streamChatUI)
            case "haha": return UIImage(named: "reaction_lol_big", in: .streamChatUI)
            case "thumbsup": return UIImage(named: "reaction_thumbsup_big", in: .streamChatUI)
            case "thumbsdown": return UIImage(named: "reaction_thumbsdown_big", in: .streamChatUI)
            case "wut": return UIImage(named: "reaction_wut_big", in: .streamChatUI)
            default: return nil
            }
        }

        public var messageActionsView: MessageActionsView<ExtraData>.Type =
            MessageActionsView<ExtraData>.self
        public var messageActionButton: MessageActionsView<ExtraData>.ActionButton.Type =
            MessageActionsView<ExtraData>.ActionButton.self
        public var messageReactionsView: ChatMessageReactionsView<ExtraData>.Type = ChatMessageReactionsView<ExtraData>.self
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
        public var threadArrowView: ChatMessageThreadArrowView<ExtraData>.Type = ChatMessageThreadArrowView<ExtraData>.self
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
        public var textView: ChatChannelMessageInputTextView<ExtraData>.Type = ChatChannelMessageInputTextView<ExtraData>.self
        public var replyBubbleView: ChatReplyBubbleView<ExtraData>.Type = ChatReplyBubbleView.self
        public var replyBubbleAvatarView: AvatarView.Type = AvatarView.self
        public var slashCommandView: MessageInputSlashCommandView<ExtraData>.Type = MessageInputSlashCommandView<ExtraData>.self
        public var suggestionsViewController: MessageComposerSuggestionsViewController<ExtraData>.Type =
            MessageComposerSuggestionsViewController<ExtraData>.self
        public var suggestionsCollectionView: MessageComposerSuggestionsCollectionView.Type =
            MessageComposerSuggestionsCollectionView<ExtraData>.self
        public var suggestionsMentionCollectionViewCell: MessageComposerMentionCollectionViewCell<ExtraData>.Type =
            MessageComposerMentionCollectionViewCell<ExtraData>.self
        public var suggestionsCommandCollectionViewCell: MessageComposerCommandCollectionViewCell<ExtraData>.Type =
            MessageComposerCommandCollectionViewCell<ExtraData>.self
        public var suggestionsMentionCellView: MessageComposerMentionCellView<ExtraData>.Type =
            MessageComposerMentionCellView<ExtraData>.self
        public var suggestionsCommandCellView: MessageComposerCommandCellView<ExtraData>.Type =
            MessageComposerCommandCellView<ExtraData>.self
        public var suggestionsCollectionViewLayout: MessageComposerSuggestionsCollectionViewLayout.Type =
            MessageComposerSuggestionsCollectionViewLayout.self
        public var mentionAvatarView: ChatChannelAvatarView<ExtraData>.Type = ChatChannelAvatarView<ExtraData>.self
        public var commandIcons: [String: UIImage] = [
            "ban": UIImage(named: "command_ban", in: .streamChatUI)!,
            "flag": UIImage(named: "command_flag", in: .streamChatUI)!,
            "giphy": UIImage(named: "command_giphy", in: .streamChatUI)!,
            "imgur": UIImage(named: "command_imgur", in: .streamChatUI)!,
            "mention": UIImage(named: "command_mention", in: .streamChatUI)!,
            "mute": UIImage(named: "command_mute", in: .streamChatUI)!,
            "unban": UIImage(named: "command_unban", in: .streamChatUI)!,
            "unmute": UIImage(named: "command_unmute", in: .streamChatUI)!
        ]
        public var fallbackCommandIcon: UIImage = UIImage(named: "command_fallback", in: .streamChatUI)!
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
