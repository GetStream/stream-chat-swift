//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct UIConfig<ExtraData: ExtraDataTypes> {
    public var channelList = ChannelListUI()
    public var channelDetail = ChannelDetailUI()
    public var messageList = MessageListUI()
    public var messageComposer = MessageComposer()
    public var currentUser = CurrentUserUI()
    public var navigation = Navigation()
    public var colorPalette = ColorPalette()
    public var loadingIndicator = LoadingIndicatorUI()

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
        public var generalBackground: UIColor = .streamWhiteSnow
        public var popupBackground: UIColor = .streamWhite
        public var shadow: UIColor = .streamModalShadow

        // MARK: - Channel List

        public var channelListActionsBackgroundColor: UIColor = .streamWhiteSmoke
        public var channelListIndicatorBorderColor: UIColor = .streamWhiteSnow
        public var channelListActionDeleteChannel: UIColor = .streamAccentRed
        public var channelListAvatarOnlineIndicator: UIColor = .streamAccentGreen
        
        // MARK: - Channel Detail
        
        public var channelDetailSectionHeaderBgColor: UIColor = .streamGrayGainsboro
        public var channelDetailIconColor: UIColor = .streamGray
        public var channelDetailDisclosureIndicatorColor: UIColor = .streamGray
        public var channelDetailDeletionColor: UIColor = .streamAccentRed

        // MARK: - Text interactions

        public var highlightedColorForColor: (UIColor) -> UIColor = { $0.withAlphaComponent(0.5) }
        public var disabledColorForColor: (UIColor) -> UIColor = { _ in .lightGray }
        public var unselectedColorForColor: (UIColor) -> UIColor = { _ in .lightGray }

        // MARK: - Message Bubbles

        public var outgoingMessageBubbleBackground: UIColor = .streamGrayGainsboro
        public var outgoingMessageBubbleBorder: UIColor = .streamGrayGainsboro
        public var incomingMessageBubbleBackground: UIColor = .streamWhite
        public var incomingMessageBubbleBorder: UIColor = .streamGrayGainsboro
        public var inactiveReactionTint: UIColor = .streamGray
        public var outgoingMessageErrorIndicatorTint: UIColor = .streamAccentRed
        public var linkMessageBubbleBackground: UIColor = .streamBlueAlice
        public var ephemeralMessageBubbleBackground: UIColor = .streamWhite
        public var giphyBadgeText: UIColor = .streamWhite

        // MARK: - Message Composer

        public var messageComposerBorder: UIColor = .streamGrayGainsboro
        public var messageComposerBackground: UIColor = .streamWhite
        public var messageComposerButton: UIColor = .streamGray
        public var messageComposerStateIcon: UIColor = .streamGrayGainsboro
        public var messageComposerPlaceholder: UIColor = .streamGray
        public var messageComposerCheckmarkBorder: UIColor = .streamGray
        public var messageComposerCheckmarkLabel: UIColor = .streamGray
        public var messageComposerCheckmark: UIColor = .streamWhite
        public var slashCommandViewBackground: UIColor = .streamAccentBlue
        public var slashCommandViewText: UIColor = .streamWhite

        // MARK: - Message interaction

        public var popupDimmedBackground: UIColor = .streamOverlay
        public var galleryMoreImagesOverlayBackground: UIColor = .streamOverlay
        public var messageTimestampText: UIColor = .streamGray
        public var unreadChatTint: UIColor = .streamGray
        public var galleryImageBackground: UIColor = .streamWhiteSmoke
        public var galleryUploadingOverlayBackground: UIColor = .streamOverlay
        public var galleryUploadingProgressBackground: UIColor = .streamOverlayDark
        public var messageActionDefaultIconTint: UIColor = .streamGray
        public var messageActionDefaultText: UIColor = .streamBlack
        public var messageActionErrorTint: UIColor = .streamAccentRed
        public var messageInteractiveAttachmentActionsBorder: UIColor = .streamGrayGainsboro
    }
}

// MARK: - Navigation

public extension UIConfig {
    struct Navigation {
        public var navigationBar: ChatNavigationBar.Type = ChatNavigationBar.self
        public var channelListRouter: ChatChannelListRouter<ExtraData>.Type = ChatChannelListRouter<ExtraData>.self
        public var messageListRouter: ChatMessageListRouter<ExtraData>.Type = ChatMessageListRouter<ExtraData>.self
        public var channelRouter: ChatChannelRouter<ExtraData>.Type = ChatChannelRouter<ExtraData>.self
        public var messageActionsRouter: ChatMessageActionsRouter<ExtraData>.Type = ChatMessageActionsRouter<ExtraData>.self
    }
}

// MARK: - ChannelListUI

public extension UIConfig {
    struct ChannelListUI {
        public var channelCollectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self
        public var channelCollectionLayout: UICollectionViewLayout.Type = ChatChannelListCollectionViewLayout.self
        public var channelListSwipeableItemView: ChatSwipeableListItemView<ExtraData>.Type =
            ChatSwipeableListItemView<ExtraData>.self
        public var channelListItemView: ChatChannelListItemView<ExtraData>.Type = ChatChannelListItemView<ExtraData>.self
        public var channelViewCell: ChatChannelListCollectionViewCell<ExtraData>.Type =
            ChatChannelListCollectionViewCell<ExtraData>.self
        public var newChannelButton: CreateNewChannelButton.Type = CreateNewChannelButton.self
        public var channelNamer: ChannelNamer.Type = ChannelNamer.self
        public var channelListItemSubviews = ChannelListItemSubviews()
    }
    
    struct ChannelListItemSubviews {
        public var avatarView: ChatChannelAvatarView<ExtraData>.Type = ChatChannelAvatarView.self
        public var unreadCountView: ChatUnreadCountView.Type = ChatUnreadCountView.self
        public var readStatusView: ChatReadStatusCheckmarkView<ExtraData>.Type = ChatReadStatusCheckmarkView<ExtraData>.self
    }
}

// MARK: - ChannelDetailUI

public extension UIConfig {
    struct ChannelDetailUI {
        public var channelDetailCollectionView: ChatChannelUserDetailCollectionView.Type =
            ChatChannelUserDetailCollectionView.self
        public var channelDetailViewCell: ChatChannelUserDetailCollectionViewCell<ExtraData>.Type =
            ChatChannelUserDetailCollectionViewCell<ExtraData>.self
        public var channelDetailItemView: ChatChannelUserDetailItemView<ExtraData>.Type =
            ChatChannelUserDetailItemView<ExtraData>.self
        
        public var icon = Icons()
        
        public struct Icons {
            public var indicator = UIImage(named: "icn_indicator", in: .streamChatUI)
            public var notification = UIImage(named: "icn_notification", in: .streamChatUI)
            public var mute = UIImage(named: "icn_mute", in: .streamChatUI)
            public var block = UIImage(named: "icn_block", in: .streamChatUI)
            public var photosAndVideos = UIImage(named: "icn_photos_videos", in: .streamChatUI)
            public var files = UIImage(named: "icn_files", in: .streamChatUI)
            public var groups = UIImage(named: "icn_shared_groups", in: .streamChatUI)
            public var leaveGroup = UIImage(named: "icn_leave_group", in: .streamChatUI)
            public var delete = UIImage(named: "icn_delete_conversation", in: .streamChatUI)
        }
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
    struct LoadingIndicatorUI {
        public var image = UIImage(named: "loading_indicator", in: .streamChatUI)!
        public var rotationPeriod: TimeInterval = 1
    }

    struct MessageListUI {
        public var messageListVC: ChatMessageListVC<ExtraData>.Type = ChatMessageListVC<ExtraData>.self
        public var incomingMessageCell: СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatIncomingMessageCollectionViewCell<ExtraData>.self
        public var outgoingMessageCell: СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatOutgoingMessageCollectionViewCell<ExtraData>.self

        public var collectionView: ChatChannelCollectionView.Type = ChatChannelCollectionView.self
        public var collectionLayout: ChatChannelCollectionViewLayout.Type = ChatChannelCollectionViewLayout.self
        public var channelNamer: ChannelNamer.Type = ChannelNamer.self
        public var minTimeInvteralBetweenMessagesInGroup: TimeInterval = 10
        /// Vertical contentOffset for message list, when next message batch should be requested
        public var offsetToPreloadMoreMessages: CGFloat = 100
        public var messageContentView: ChatMessageContentView<ExtraData>.Type = ChatMessageContentView<ExtraData>.self
        public var messageContentSubviews = MessageContentViewSubviews()
        public var messageActionsSubviews = MessageActionsSubviews()
        public var messageReactions = MessageReactions()
    }

    struct MessageActionsSubviews {
        public var actionsView: MessageActionsView<ExtraData>.Type =
            MessageActionsView<ExtraData>.self
        public var actionButton: MessageActionsView<ExtraData>.ActionButton.Type =
            MessageActionsView<ExtraData>.ActionButton.self
    }

    struct MessageReactions {
        public var reactionsBubbleView: ChatMessageReactionsBubbleView<ExtraData>.Type =
            ChatMessageDefaultReactionsBubbleView<ExtraData>.self
        public var reactionsView: ChatMessageReactionsView<ExtraData>.Type = ChatMessageReactionsView<ExtraData>.self
        public var reactionItemView: ChatMessageReactionsView<ExtraData>.ItemView.Type =
            ChatMessageReactionsView<ExtraData>.ItemView.self

        public var availableReactions: [MessageReactionType: ReactionAppearanceType] = [
            .init(rawValue: "love"): ReactionAppearance(
                smallIcon: UIImage(named: "reaction_love_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_love_big", in: .streamChatUI)!
            ),
            .init(rawValue: "haha"): ReactionAppearance(
                smallIcon: UIImage(named: "reaction_lol_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_lol_big", in: .streamChatUI)!
            ),
            .init(rawValue: "like"): ReactionAppearance(
                smallIcon: UIImage(named: "reaction_thumbsup_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_thumbsup_big", in: .streamChatUI)!
            ),
            .init(rawValue: "sad"): ReactionAppearance(
                smallIcon: UIImage(named: "reaction_thumbsdown_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_thumbsdown_big", in: .streamChatUI)!
            ),
            .init(rawValue: "wow"): ReactionAppearance(
                smallIcon: UIImage(named: "reaction_wut_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_wut_big", in: .streamChatUI)!
            )
        ]
    }

    struct MessageContentViewSubviews {
        public var authorAvatarView: AvatarView.Type = AvatarView.self
        public var bubbleView: ChatMessageBubbleView<ExtraData>.Type = ChatMessageBubbleView<ExtraData>.self
        public var metadataView: ChatMessageMetadataView<ExtraData>.Type = ChatMessageMetadataView<ExtraData>.self
        public var repliedMessageContentView: ChatRepliedMessageContentView<ExtraData>.Type =
            ChatRepliedMessageContentView<ExtraData>.self
        public var attachmentSubviews = MessageAttachmentViewSubviews()
        public var onlyVisibleForCurrentUserIndicator: ChatMessageOnlyVisibleForCurrentUserIndicator.Type =
            ChatMessageOnlyVisibleForCurrentUserIndicator.self
        public var threadArrowView: ChatMessageThreadArrowView<ExtraData>.Type = ChatMessageThreadArrowView<ExtraData>.self
        public var threadInfoView: ChatMessageThreadInfoView<ExtraData>.Type = ChatMessageThreadInfoView<ExtraData>.self
        public var errorIndicator: ChatMessageErrorIndicator<ExtraData>.Type = ChatMessageErrorIndicator<ExtraData>.self
        public var linkPreviewView: ChatMessageLinkPreviewView<ExtraData>.Type = ChatMessageLinkPreviewView<ExtraData>.self
    }

    struct MessageAttachmentViewSubviews {
        public var loadingIndicator: LoadingIndicator<ExtraData>.Type = LoadingIndicator<ExtraData>.self
        public var attachmentsView: ChatMessageAttachmentsView<ExtraData>.Type = ChatMessageAttachmentsView<ExtraData>.self
        // Files
        public var fileAttachmentListView: ChatFileAttachmentListView<ExtraData>.Type = ChatFileAttachmentListView<ExtraData>.self
        public var fileAttachmentItemView: ChatFileAttachmentListView<ExtraData>.ItemView.Type =
            ChatFileAttachmentListView<ExtraData>.ItemView.self
        public var fileFallbackIcon = UIImage(named: "generic", in: .streamChatUI)!
        public var fileIcons = [AttachmentFileType: UIImage](
            uniqueKeysWithValues: AttachmentFileType.allCases.compactMap {
                guard let icon = UIImage(named: $0.rawValue, in: .streamChatUI) else { return nil }
                return ($0, icon)
            }
        )
        public var fileAttachmentActionIcons: [LocalAttachmentState?: UIImage] = [
            .uploaded: UIImage(named: "uploaded", in: .streamChatUI)!,
            .uploadingFailed: UIImage(named: "restart", in: .streamChatUI)!,
            nil: UIImage(named: "download_and_open", in: .streamChatUI)!
        ]
        // Images
        public var imageGallery: ChatMessageImageGallery<ExtraData>.Type = ChatMessageImageGallery<ExtraData>.self
        public var imageGalleryItem: ChatMessageImageGallery<ExtraData>.ImagePreview.Type =
            ChatMessageImageGallery<ExtraData>.ImagePreview.self
        public var imageGalleryInteritemSpacing: CGFloat = 2
        public var imageGalleryItemUploadingOverlay: ChatMessageImageGallery<ExtraData>.UploadingOverlay.Type =
            ChatMessageImageGallery<ExtraData>.UploadingOverlay.self
        // Interactive attachments
        public var interactiveAttachmentView: ChatMessageInteractiveAttachmentView<ExtraData>.Type =
            ChatMessageInteractiveAttachmentView<ExtraData>.self
        public var interactiveAttachmentActionButton: ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
            ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self
        // Giphy
        public var giphyAttachmentView: ChatMessageGiphyView<ExtraData>.Type =
            ChatMessageGiphyView<ExtraData>.self
        public var giphyBadgeView: ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = ChatMessageGiphyView<ExtraData>.GiphyBadge.self
        public var giphyBadgeIcon: UIImage? = UIImage(named: "icon_giphy", in: .streamChatUI)
    }
}

// MARK: - MessageComposer

public extension UIConfig {
    struct MessageComposer {
        public var messageComposerViewController: MessageComposerViewController<ExtraData>.Type =
            MessageComposerViewController<ExtraData>.self
        public var messageComposerView: MessageComposerView<ExtraData>.Type =
            MessageComposerView<ExtraData>.self
        public var messageInputView: MessageComposerInputContainerView<ExtraData>
            .Type = MessageComposerInputContainerView<ExtraData>.self
        public var documentAttachmentView: MessageComposerDocumentAttachmentView<ExtraData>.Type =
            MessageComposerDocumentAttachmentView<ExtraData>.self
        public var documentAttachmentsFlowLayout: MessageComposerDocumentAttachmentsCollectionViewLayout.Type =
            MessageComposerDocumentAttachmentsCollectionViewLayout.self
        public var imageAttachmentsView: MessageComposerImageAttachmentsView<ExtraData>.Type =
            MessageComposerImageAttachmentsView<ExtraData>.self
        public var documentAttachmentsView: MessageComposerDocumentAttachmentsView<ExtraData>.Type =
            MessageComposerDocumentAttachmentsView<ExtraData>.self
        public var sendButton: MessageComposerSendButton<ExtraData>.Type = MessageComposerSendButton<ExtraData>.self
        public var composerButton: ChatSquareButton<ExtraData>.Type = ChatSquareButton<ExtraData>.self
        public var textView: MessageComposerInputTextView<ExtraData>.Type = MessageComposerInputTextView<ExtraData>.self
        public var replyBubbleView: ChatReplyBubbleView<ExtraData>.Type = ChatReplyBubbleView.self
        public var replyBubbleAvatarView: AvatarView.Type = AvatarView.self
        public var checkmarkControl: MessageComposerCheckmarkControl<ExtraData>.Type =
            MessageComposerCheckmarkControl<ExtraData>.self
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
        public var suggestionsHeaderReusableView: MessageComposerSuggestionsCommandsReusableView<ExtraData>.Type =
            MessageComposerSuggestionsCommandsReusableView.self
        public var suggestionsHeaderView: MessageComposerSuggestionsCommandsHeaderView<ExtraData>.Type =
            MessageComposerSuggestionsCommandsHeaderView.self
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
        public var documentPreviews: [String: UIImage] = [
            "7z": UIImage(named: "7z", in: .streamChatUI)!,
            "csv": UIImage(named: "csv", in: .streamChatUI)!,
            "doc": UIImage(named: "doc", in: .streamChatUI)!,
            "docx": UIImage(named: "docx", in: .streamChatUI)!,
            "html": UIImage(named: "html", in: .streamChatUI)!,
            "md": UIImage(named: "md", in: .streamChatUI)!,
            "mp3": UIImage(named: "mp3", in: .streamChatUI)!,
            "odt": UIImage(named: "odt", in: .streamChatUI)!,
            "pdf": UIImage(named: "pdf", in: .streamChatUI)!,
            "ppt": UIImage(named: "ppt", in: .streamChatUI)!,
            "pptx": UIImage(named: "pptx", in: .streamChatUI)!,
            "rar": UIImage(named: "rar", in: .streamChatUI)!,
            "rtf": UIImage(named: "rtf", in: .streamChatUI)!,
            "tar.gz": UIImage(named: "tar.gz", in: .streamChatUI)!,
            "txt": UIImage(named: "txt", in: .streamChatUI)!,
            "xls": UIImage(named: "xls", in: .streamChatUI)!,
            "xlsx": UIImage(named: "xlsx", in: .streamChatUI)!,
            "zip": UIImage(named: "zip", in: .streamChatUI)!
        ]
        public var fallbackDocumentPreview: UIImage = UIImage(named: "generic", in: .streamChatUI)!
    }
}

// MARK: - Steam constants

private extension UIColor {
    /// This is color palette used by design team.
    /// If you see any color not from this list in figma, point it out to anyone in design team.
    static let streamBlack = mode(0x000000, 0xffffff)
    static let streamGray = mode(0x7a7a7a, 0x7a7a7a)
    static let streamGrayGainsboro = mode(0xdbdbdb, 0x2d2f2f)
    static let streamGrayWhisper = mode(0xecebeb, 0x1c1e22)
    static let streamWhiteSmoke = mode(0xf2f2f2, 0x13151b)
    static let streamWhiteSnow = mode(0xfcfcfc, 0x070a0d)
    static let streamWhite = mode(0xffffff, 0x101418)
    static let streamBlueAlice = mode(0xe9f2ff, 0x00193d)
    static let streamAccentBlue = mode(0x005fff, 0x005fff)
    static let streamAccentRed = mode(0xff3742, 0xff3742)
    static let streamAccentGreen = mode(0x20e070, 0x20e070)
    static let streamModalShadow = mode(0, lightAlpha: 0.15, 0, darkAlpha: 1)

    static let streamBGGradientFrom = mode(0xf7f7f7, 0x101214)
    static let streamBGGradientTo = mode(0xfcfcfc, 0x070a0d)
    static let streamOverlay = mode(0x000000, lightAlpha: 0.2, 0x000000, darkAlpha: 0.4)
    static let streamOverlayDark = mode(0x000000, lightAlpha: 0.6, 0xffffff, darkAlpha: 0.8)

    static func mode(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(rgb: dark).withAlphaComponent(darkAlpha)
                    : UIColor(rgb: light).withAlphaComponent(lightAlpha)
            }
        } else {
            return UIColor(rgb: light).withAlphaComponent(lightAlpha)
        }
    }
}
