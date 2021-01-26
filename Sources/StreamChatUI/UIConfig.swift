//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    public var font = Font()
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
        public var channelListUnreadCountView: UIColor = .streamAccentRed
        public var channelListUnreadCountLabel: UIColor = .streamWhite

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

public extension UIConfig {
    struct Font {
        public var captionBold: UIFont = .streamCaptionBold
        public var footnote: UIFont = .streamFootnote
        public var footnoteBold: UIFont = .streamFootnoteBold
        public var body: UIFont = .streamBody
        public var bodyBold: UIFont = .streamBodyBold
        public var bodyItalic: UIFont = .streamBodyItalic
        public var headline: UIFont = .streamHeadline
        public var headlineBold: UIFont = .streamHeadlineBold
        public var title: UIFont = .streamTitle
    }
}

// MARK: - Navigation

public extension UIConfig {
    struct Navigation {
        public var navigationBar: ChatNavigationBar.Type = ChatNavigationBar.self
        public var channelListRouter: _ChatChannelListRouter<ExtraData>.Type = _ChatChannelListRouter<ExtraData>.self
        public var messageListRouter: _ChatMessageListRouter<ExtraData>.Type = _ChatMessageListRouter<ExtraData>.self
        public var channelDetailRouter: _ChatChannelRouter<ExtraData>.Type = _ChatChannelRouter<ExtraData>.self
        public var messageActionsRouter: _ChatMessageActionsRouter<ExtraData>.Type = _ChatMessageActionsRouter<ExtraData>.self
    }
}

// MARK: - ChannelListUI

public extension UIConfig {
    struct ChannelListUI {
        public var channelCollectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self
        public var channelCollectionLayout: UICollectionViewLayout.Type = ChatChannelListCollectionViewLayout.self
        public var channelListSwipeableItemView: _ChatChannelSwipeableListItemView<ExtraData>.Type =
            _ChatChannelSwipeableListItemView<ExtraData>.self
        public var channelListItemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self
        public var channelViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self
        public var newChannelButton: CreateNewChannelButton.Type = CreateNewChannelButton.self
        public var channelNamer: ChatChannelNamer.Type = ChatChannelNamer.self
        public var channelListItemSubviews = ChannelListItemSubviews()
    }
    
    struct ChannelListItemSubviews {
        public var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self
        public var unreadCountView: _ChatChannelUnreadCountView<ExtraData>.Type = _ChatChannelUnreadCountView<ExtraData>.self
        public var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData>.Type =
            _ChatChannelReadStatusCheckmarkView<ExtraData>.self
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
        public var messageListVC: _ChatMessageListVC<ExtraData>.Type = _ChatMessageListVC<ExtraData>.self
        public var incomingMessageCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatIncomingMessageCollectionViewCell<ExtraData>.self
        public var outgoingMessageCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatOutgoingMessageCollectionViewCell<ExtraData>.self

        public var collectionView: ChatMessageListCollectionView.Type = ChatMessageListCollectionView.self
        public var collectionLayout: ChatMessageListCollectionViewLayout.Type = ChatMessageListCollectionViewLayout.self
        public var channelNamer: ChatChannelNamer.Type = ChatChannelNamer.self
        public var minTimeInvteralBetweenMessagesInGroup: TimeInterval = 10
        /// Vertical contentOffset for message list, when next message batch should be requested
        public var offsetToPreloadMoreMessages: CGFloat = 100
        public var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self
        public var messageContentSubviews = MessageContentViewSubviews()
        public var messageActionsSubviews = MessageActionsSubviews()
        public var messageReactions = MessageReactions()
    }

    struct MessageActionsSubviews {
        public var actionsView: _ChatMessageActionsView<ExtraData>.Type =
            _ChatMessageActionsView<ExtraData>.self
        public var actionButton: _ChatMessageActionsView<ExtraData>.ActionButton.Type =
            _ChatMessageActionsView<ExtraData>.ActionButton.self
    }

    struct MessageReactions {
        public var reactionsBubbleView: _ChatMessageReactionsBubbleView<ExtraData>.Type =
            _ChatMessageDefaultReactionsBubbleView<ExtraData>.self
        public var reactionsView: _ChatMessageReactionsView<ExtraData>.Type = _ChatMessageReactionsView<ExtraData>.self
        public var reactionItemView: _ChatMessageReactionsView<ExtraData>.ItemView.Type =
            _ChatMessageReactionsView<ExtraData>.ItemView.self

        public var availableReactions: [MessageReactionType: ChatMessageReactionAppearanceType] = [
            .init(rawValue: "love"): ChatMessageReactionAppearance(
                smallIcon: UIImage(named: "reaction_love_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_love_big", in: .streamChatUI)!
            ),
            .init(rawValue: "haha"): ChatMessageReactionAppearance(
                smallIcon: UIImage(named: "reaction_lol_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_lol_big", in: .streamChatUI)!
            ),
            .init(rawValue: "like"): ChatMessageReactionAppearance(
                smallIcon: UIImage(named: "reaction_thumbsup_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_thumbsup_big", in: .streamChatUI)!
            ),
            .init(rawValue: "sad"): ChatMessageReactionAppearance(
                smallIcon: UIImage(named: "reaction_thumbsdown_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_thumbsdown_big", in: .streamChatUI)!
            ),
            .init(rawValue: "wow"): ChatMessageReactionAppearance(
                smallIcon: UIImage(named: "reaction_wut_small", in: .streamChatUI)!,
                largeIcon: UIImage(named: "reaction_wut_big", in: .streamChatUI)!
            )
        ]
    }

    struct MessageContentViewSubviews {
        public var authorAvatarView: AvatarView.Type = AvatarView.self
        public var bubbleView: _ChatMessageBubbleView<ExtraData>.Type = _ChatMessageBubbleView<ExtraData>.self
        public var metadataView: _ChatMessageMetadataView<ExtraData>.Type = _ChatMessageMetadataView<ExtraData>.self
        public var quotedMessageBubbleView: _ChatMessageQuoteBubbleView<ExtraData>.Type = _ChatMessageQuoteBubbleView.self
        public var attachmentSubviews = MessageAttachmentViewSubviews()
        public var onlyVisibleForCurrentUserIndicator: ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData>.Type =
            ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData>.self
        public var threadArrowView: _ChatMessageThreadArrowView<ExtraData>.Type = _ChatMessageThreadArrowView<ExtraData>.self
        public var threadInfoView: _ChatMessageThreadInfoView<ExtraData>.Type = _ChatMessageThreadInfoView<ExtraData>.self
        public var errorIndicator: _ChatMessageErrorIndicator<ExtraData>.Type = _ChatMessageErrorIndicator<ExtraData>.self
        public var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>.Type = _ChatMessageLinkPreviewView<ExtraData>.self
    }

    struct MessageAttachmentViewSubviews {
        public var loadingIndicator: LoadingIndicator<ExtraData>.Type = LoadingIndicator<ExtraData>.self
        public var attachmentsView: _ChatMessageAttachmentsView<ExtraData>.Type = _ChatMessageAttachmentsView<ExtraData>.self
        // Files
        public var fileAttachmentListView: _ChatMessageFileAttachmentListView<ExtraData>
            .Type = _ChatMessageFileAttachmentListView<ExtraData>.self
        public var fileAttachmentItemView: _ChatMessageFileAttachmentListView<ExtraData>.ItemView.Type =
            _ChatMessageFileAttachmentListView<ExtraData>.ItemView.self
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
        public var imageGallery: _ChatMessageImageGallery<ExtraData>.Type = _ChatMessageImageGallery<ExtraData>.self
        public var imageGalleryItem: _ChatMessageImageGallery<ExtraData>.ImagePreview.Type =
            _ChatMessageImageGallery<ExtraData>.ImagePreview.self
        public var imageGalleryInteritemSpacing: CGFloat = 2
        public var imageGalleryItemUploadingOverlay: _ChatMessageImageGallery<ExtraData>.UploadingOverlay.Type =
            _ChatMessageImageGallery<ExtraData>.UploadingOverlay.self
        // Interactive attachments
        public var interactiveAttachmentView: _ChatMessageInteractiveAttachmentView<ExtraData>.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.self
        public var interactiveAttachmentActionButton: _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self
        // Giphy
        public var giphyAttachmentView: _ChatMessageGiphyView<ExtraData>.Type =
            _ChatMessageGiphyView<ExtraData>.self
        public var giphyBadgeView: _ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = _ChatMessageGiphyView<ExtraData>.GiphyBadge
            .self
        public var giphyBadgeIcon: UIImage? = UIImage(named: "icon_giphy", in: .streamChatUI)
    }
}

// MARK: - MessageComposer

public extension UIConfig {
    struct MessageComposer {
        public var messageComposerViewController: _ChatMessageComposerVC<ExtraData>.Type =
            _ChatMessageComposerVC<ExtraData>.self
        public var messageComposerView: _ChatMessageComposerView<ExtraData>.Type =
            _ChatMessageComposerView<ExtraData>.self
        public var messageInputView: _ChatMessageComposerInputContainerView<ExtraData>
            .Type = _ChatMessageComposerInputContainerView<ExtraData>.self
        public var documentAttachmentView: _ChatMessageComposerDocumentAttachmentView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentView<ExtraData>.self
        public var documentAttachmentsFlowLayout: ChatMessageComposerDocumentAttachmentsCollectionViewLayout.Type =
            ChatMessageComposerDocumentAttachmentsCollectionViewLayout.self
        public var imageAttachmentsView: _ChatMessageComposerImageAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentsView<ExtraData>.self
        public var documentAttachmentsView: _ChatMessageComposerDocumentAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentsView<ExtraData>.self
        public var sendButton: _ChatMessageComposerSendButton<ExtraData>.Type = _ChatMessageComposerSendButton<ExtraData>.self
        public var composerButton: ChatSquareButton<ExtraData>.Type = ChatSquareButton<ExtraData>.self
        public var textView: _ChatMessageComposerInputTextView<ExtraData>.Type = _ChatMessageComposerInputTextView<ExtraData>.self
        public var quotedMessageView: _ChatMessageComposerQuoteBubbleView<ExtraData>.Type = _ChatMessageComposerQuoteBubbleView.self
        public var quotedMessageAvatarView: AvatarView.Type = AvatarView.self
        public var checkmarkControl: _ChatMessageComposerCheckmarkControl<ExtraData>.Type =
            _ChatMessageComposerCheckmarkControl<ExtraData>.self
        public var slashCommandView: _ChatMessageInputSlashCommandView<ExtraData>
            .Type = _ChatMessageInputSlashCommandView<ExtraData>.self
        public var suggestionsViewController: _ChatMessageComposerSuggestionsViewController<ExtraData>.Type =
            _ChatMessageComposerSuggestionsViewController<ExtraData>.self
        public var suggestionsCollectionView: _ChatMessageComposerSuggestionsCollectionView.Type =
            _ChatMessageComposerSuggestionsCollectionView<ExtraData>.self
        public var suggestionsMentionCollectionViewCell: _ChatMessageComposerMentionCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerMentionCollectionViewCell<ExtraData>.self
        public var suggestionsCommandCollectionViewCell: _ChatMessageComposerCommandCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerCommandCollectionViewCell<ExtraData>.self
        public var suggestionsMentionCellView: _ChatMessageComposerMentionCellView<ExtraData>.Type =
            _ChatMessageComposerMentionCellView<ExtraData>.self
        public var suggestionsCommandCellView: _ChatMessageComposerCommandCellView<ExtraData>.Type =
            _ChatMessageComposerCommandCellView<ExtraData>.self
        public var suggestionsCollectionViewLayout: ChatMessageComposerSuggestionsCollectionViewLayout.Type =
            ChatMessageComposerSuggestionsCollectionViewLayout.self
        public var suggestionsHeaderReusableView: _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsReusableView.self
        public var suggestionsHeaderView: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsHeaderView.self
        public var mentionAvatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView<ExtraData>.self
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

// Typography defined in Figma design.
// Because our design guidelines don't really fit the `prefferedFont`, we need to redaclare this.
private extension UIFont {
    static let streamCaptionBold = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: boldSystemFont(ofSize: 10))
    static let streamFootnote = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))
    static let streamFootnoteBold = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: boldSystemFont(ofSize: 12))
    static let streamBody = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 14))
    static let streamBodyBold = UIFontMetrics(forTextStyle: .body).scaledFont(for: boldSystemFont(ofSize: 14))
    static let streamBodyItalic = UIFontMetrics(forTextStyle: .body).scaledFont(for: italicSystemFont(ofSize: 14))
    static let streamHeadline = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 16))
    static let streamHeadlineBold = UIFontMetrics(forTextStyle: .headline).scaledFont(for: boldSystemFont(ofSize: 16))
    static let streamTitle = UIFontMetrics(forTextStyle: .title1).scaledFont(for: boldSystemFont(ofSize: 22))
}
