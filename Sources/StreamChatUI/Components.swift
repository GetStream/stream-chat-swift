//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An object containing types of UI Components that are used through the UI SDK.
public typealias Components = _Components<NoExtraData>

/// An object containing types of UI Components that are used through the UI SDK.
public struct _Components<ExtraData: ExtraDataTypes> {
    /// The view used as a navigation bar title view for some view controllers.
    public var navigationTitleView: TitleContainerView.Type = TitleContainerView.self

    /// A view used as an online activity indicator (online/offline).
    public var onlineIndicatorView: (UIView & MaskProviding).Type = OnlineIndicatorView.self

    /// A view that displays the avatar image. By default a circular image.
    public var avatarView: ChatAvatarView.Type = ChatAvatarView.self

    /// An avatar view with an online indicator.
    public var presenceAvatarView: _ChatPresenceAvatarView<ExtraData>.Type = _ChatPresenceAvatarView<ExtraData>.self

    /// A `UIView` subclass which serves as container for `typingIndicator` and `UILabel` describing who is currently typing
    public var typingIndicatorView: _TypingIndicatorView<ExtraData>.Type = _TypingIndicatorView<ExtraData>.self
    
    /// A `UIView` subclass with animated 3 dots for indicating that user is typing.
    public var typingAnimationView: TypingAnimationView.Type = TypingAnimationView.self

    /// A view for inputting text with placeholder support.
    public var inputTextView: InputTextView.Type = InputTextView.self

    /// A view that displays the command name and icon.
    public var commandLabelView: CommandLabelView.Type = CommandLabelView.self

    /// A view to input content of a message.
    public var inputMessageView: _InputChatMessageView<ExtraData>.Type = _InputChatMessageView<ExtraData>.self

    /// A view that displays a quoted message.
    public var quotedMessageView: _QuotedChatMessageView<ExtraData>.Type = _QuotedChatMessageView<ExtraData>.self

    /// A button used for sending a message, or any type of content.
    public var sendButton: UIButton.Type = SendButton.self

    /// A button for confirming actions.
    public var confirmButton: UIButton.Type = ConfirmButton.self

    /// A button for opening attachments.
    public var attachmentButton: UIButton.Type = AttachmentButton.self

    /// A view used as a fallback preview view for attachments that don't confirm to `AttachmentPreviewProvider`
    public var attachmentPreviewViewPlaceholder: UIView.Type = AttachmentPlaceholderView.self

    /// A button for opening commands.
    public var commandsButton: UIButton.Type = CommandButton.self

    /// A button for shrinking the input view to allow more space for other actions.
    public var shrinkInputButton: UIButton.Type = ShrinkInputButton.self

    /// A button for closing, dismissing or clearing information.
    public var closeButton: UIButton.Type = CloseButton.self
    
    /// A button for sharing an information.
    public var shareButton: UIButton.Type = ShareButton.self

    /// A view to check/uncheck an option.
    public var checkmarkControl: CheckboxControl.Type = CheckboxControl.self

    /// An object responsible for message layout options calculations in `ChatMessageListVC/ChatThreadVC`.
    public var messageLayoutOptionsResolver: _ChatMessageLayoutOptionsResolver<ExtraData> = .init()
    
    /// The view that shows a loading indicator.
    public var loadingIndicator: ChatLoadingIndicator.Type = ChatLoadingIndicator.self
    
    /// Object with set of function for handling images from CDN
    public var imageCDN: ImageCDN = StreamImageCDN()

    /// The object that loads previews for video attachments.
    public var videoPreviewLoader: VideoPreviewLoader = DefaultVideoPreviewLoader()
    
    /// The view that shows a gradient.
    public var gradientView: GradientView.Type = GradientView.self
    
    /// The view that shows a playing video.
    public var playerView: PlayerView.Type = PlayerView.self
    
    // MARK: - Message list components

    /// The View Controller used to display content of the message, i.e. in the channel detail message list.
    public var messageListVC: _ChatMessageListVC<ExtraData>.Type = _ChatMessageListVC<ExtraData>.self

    /// The view that shows the message list.
    public var messageListView: _ChatMessageListView<ExtraData>.Type = _ChatMessageListView<ExtraData>
        .self

    /// The view that shows the date for currently visible messages on top of message list.
    public var messageListScrollOverlayView: ChatMessageListScrollOverlayView.Type = ChatMessageListScrollOverlayView.self
    
    /// The View Controller used to display the detail of a message thread.
    public var threadVC: _ChatThreadVC<ExtraData>.Type = _ChatThreadVC<ExtraData>.self

    /// The View Controller by default used to display message actions after long-pressing on the message.
    public var messageActionsVC: _ChatMessageActionsVC<ExtraData>.Type = _ChatMessageActionsVC<ExtraData>.self

    /// The View Controller by default used to display interactive reactions view after long-pressing on the message.
    public var messageReactionsVC: _ChatMessageReactionsVC<ExtraData>.Type = _ChatMessageReactionsVC<ExtraData>.self

    /// The View Controller by default used to display long-press menu of the message.
    public var messagePopupVC: _ChatMessagePopupVC<ExtraData>.Type = _ChatMessagePopupVC<ExtraData>.self

    /// The View Controller used for showing detail of a file message attachment.
    public var filePreviewVC: ChatMessageAttachmentPreviewVC.Type = ChatMessageAttachmentPreviewVC.self

    /// The View Controller used for show image and video attachments.
    public var galleryVC: _GalleryVC<ExtraData>.Type = _GalleryVC<ExtraData>.self
    
    /// The view used to control the player for currently visible vide attachment.
    public var videoPlaybackControlView: _VideoPlaybackControlView<ExtraData>.Type =
        _VideoPlaybackControlView<ExtraData>.self
    
    /// The view used to display content of the message, i.e. in the channel detail message list.
    public var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self

    /// The view used to display a bubble around a message.
    public var messageBubbleView: _ChatMessageBubbleView<ExtraData>.Type = _ChatMessageBubbleView<ExtraData>.self

    /// The class responsible for returning the correct attachment view injector from a message
    public var attachmentViewCatalog: _AttachmentViewCatalog<ExtraData>.Type = _AttachmentViewCatalog<ExtraData>.self

    /// The injector used to inject gallery attachment views.
    public var galleryAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GalleryAttachmentViewInjector<ExtraData>.self

    /// The injector used to inject link attachment views.
    public var linkAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _LinkAttachmentViewInjector<ExtraData>.self

    /// The injector used for injecting giphy attachment views
    public var giphyAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GiphyAttachmentViewInjector<ExtraData>.self

    /// The injector used for injecting file attachment views
    public var filesAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _FilesAttachmentViewInjector<ExtraData>.self

    /// The view that shows reactions bubble.
    public var reactionsBubbleView: _ChatMessageReactionsBubbleView<ExtraData>.Type =
        _ChatMessageDefaultReactionsBubbleView<ExtraData>.self
    
    /// The button for taking an action on attachment being uploaded.
    public var attachmentActionButton: AttachmentActionButton.Type = AttachmentActionButton.self

    /// The view that shows reactions list in a bubble.
    public var reactionsView: _ChatMessageReactionsView<ExtraData>.Type = _ChatMessageReactionsView<ExtraData>.self

    /// The view that shows a single reaction.
    public var reactionItemView: _ChatMessageReactionsView<ExtraData>.ItemView.Type =
        _ChatMessageReactionsView<ExtraData>.ItemView.self
    
    /// The view that shows error indicator in `messageContentView`.
    public var messageErrorIndicator: ChatMessageErrorIndicator.Type = ChatMessageErrorIndicator.self

    /// The view that shows message's file attachments.
    public var fileAttachmentListView: _ChatMessageFileAttachmentListView<ExtraData>
        .Type = _ChatMessageFileAttachmentListView<ExtraData>.self

    /// The view that shows a single file attachment.
    public var fileAttachmentView: _ChatMessageFileAttachmentListView<ExtraData>.ItemView.Type =
        _ChatMessageFileAttachmentListView<ExtraData>.ItemView.self
    
    /// The view that shows a link preview in message cell.
    public var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>.Type =
        _ChatMessageLinkPreviewView<ExtraData>.self
    
    /// The view that shows message's image and video attachments.
    public var galleryView: _ChatMessageGalleryView<ExtraData>.Type =
        _ChatMessageGalleryView<ExtraData>.self
    
    /// The view that shows an image attachment preview inside message cell.
    public var imageAttachmentGalleryPreview: _ChatMessageGalleryView<ExtraData>.ImagePreview.Type =
        _ChatMessageGalleryView<ExtraData>.ImagePreview.self
    
    /// The view that shows a video attachment in full-screen gallery.
    public var videoAttachmentGalleryCell: _VideoAttachmentGalleryCell<ExtraData>.Type =
        _VideoAttachmentGalleryCell<ExtraData>.self
    
    /// The view that shows a video attachment preview inside a message.
    public var videoAttachmentGalleryPreview: _VideoAttachmentGalleryPreview<ExtraData>.Type =
        _VideoAttachmentGalleryPreview<ExtraData>.self
    
    /// The view that shows an overlay with uploading progress for image attachment that is being uploaded.
    public var imageUploadingOverlay: _ChatMessageGalleryView<ExtraData>.UploadingOverlay.Type =
        _ChatMessageGalleryView<ExtraData>.UploadingOverlay.self

    /// The view that shows giphy attachment with actions.
    public var giphyAttachmentView: _ChatMessageInteractiveAttachmentView<ExtraData>.Type =
        _ChatMessageInteractiveAttachmentView<ExtraData>.self

    /// The button that shows the attachment action.
    public var giphyActionButton: _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
        _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self

    /// The view that shows a content for `.giphy` attachment.
    public var giphyView: _ChatMessageGiphyView<ExtraData>.Type =
        _ChatMessageGiphyView<ExtraData>.self

    /// The view that shows a badge on `giphyAttachmentView`.
    public var giphyBadgeView: _ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = _ChatMessageGiphyView<ExtraData>.GiphyBadge.self
    
    /// The button that indicates unread messages at the bottom of the message list and scroll to the latest message on tap.
    public var scrollToLatestMessageButton: _ScrollToLatestMessageButton<ExtraData>.Type =
        _ScrollToLatestMessageButton<ExtraData>.self

    /// The view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.
    public var messageListUnreadCountView: _ChatMessageListUnreadCountView<ExtraData>.Type =
        _ChatMessageListUnreadCountView<ExtraData>.self
    
    // MARK: - Channel list components

    /// The logic to generate a name for the given channel.
    public var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()

    /// The collection view layout of the channel list.
    public var channelListLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

    /// The `UICollectionViewCell` subclass that shows channel information.
    public var channelCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
        _ChatChannelListCollectionViewCell<ExtraData>.self

    /// The channel cell separator in the channel list.
    public var channelCellSeparator: UICollectionReusableView.Type = CellSeparatorReusableView.self

    /// The view in the channel cell that shows channel actions on swipe.
    public var channelActionsView: _SwipeableView<ExtraData>.Type =
        _SwipeableView<ExtraData>.self
    
    /// The view that shows channel information.
    public var channelContentView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self

    /// The view that shows a user avatar including an indicator of the user presence (online/offline).
    public var channelAvatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self

    /// The view that shows a number of unread messages in channel.
    public var channelUnreadCountView: ChatChannelUnreadCountView.Type = ChatChannelUnreadCountView.self

    /// The view that shows a read/unread status of the last message in channel.
    public var channelReadStatusView: ChatChannelReadStatusCheckmarkView.Type =
        ChatChannelReadStatusCheckmarkView.self

    // MARK: - Message composer components

    /// The view controller used to compose a message.
    public var messageComposerVC: _ComposerVC<ExtraData>.Type =
        _ComposerVC<ExtraData>.self

    /// The view that shows the message when it's being composed.
    public var messageComposerView: _ComposerView<ExtraData>.Type =
        _ComposerView<ExtraData>.self

    /// A view controller that handles the attachments.
    public var messageComposerAttachmentsVC: _AttachmentsPreviewVC<ExtraData>.Type =
        _AttachmentsPreviewVC<ExtraData>.self

    /// A view that holds the attachment views and provide extra functionality over them.
    public var messageComposerAttachmentCell: AttachmentPreviewContainer.Type = AttachmentPreviewContainer.self

    /// A view that displays the document attachment.
    public var messageComposerFileAttachmentView: FileAttachmentView.Type = FileAttachmentView.self

    /// A view that displays image attachment preview in composer.
    public var imageAttachmentComposerPreview: _ImageAttachmentComposerPreview<ExtraData>
        .Type = _ImageAttachmentComposerPreview<ExtraData>.self
    
    /// A view that displays the video attachment preview in composer.
    public var videoAttachmentComposerPreview: _VideoAttachmentComposerPreview<ExtraData>
        .Type = _VideoAttachmentComposerPreview<ExtraData>.self
    
    /// A view controller that shows suggestions of commands or mentions.
    public var suggestionsVC: _ChatSuggestionsVC<ExtraData>.Type =
        _ChatSuggestionsVC<ExtraData>.self

    /// The collection view of the suggestions view controller.
    public var suggestionsCollectionView: _ChatSuggestionsCollectionView<ExtraData>.Type =
        _ChatSuggestionsCollectionView<ExtraData>.self

    /// A view cell that displays the the suggested mention.
    public var suggestionsMentionCollectionViewCell: _ChatMentionSuggestionCollectionViewCell<ExtraData>.Type =
        _ChatMentionSuggestionCollectionViewCell<ExtraData>.self

    /// A view cell that displays the suggested command.
    public var suggestionsCommandCollectionViewCell: _ChatCommandSuggestionCollectionViewCell<ExtraData>.Type =
        _ChatCommandSuggestionCollectionViewCell<ExtraData>.self

    /// A type for view embed in cell while tagging users with @ symbol in composer.
    public var suggestionsMentionView: _ChatMentionSuggestionView<ExtraData>.Type =
        _ChatMentionSuggestionView<ExtraData>.self

    /// A view that displays the command name, image and arguments.
    public var suggestionsCommandView: ChatCommandSuggestionView.Type =
        ChatCommandSuggestionView.self

    /// The collection view layout of the suggestions collection view.
    public var suggestionsCollectionViewLayout: UICollectionViewLayout.Type =
        ChatSuggestionsCollectionViewLayout.self

    /// The header reusable view of the suggestion collection view.
    public var suggestionsHeaderReusableView: UICollectionReusableView.Type =
        _ChatSuggestionsCollectionReusableView<ExtraData>.self

    /// The header view of the suggestion collection view.
    public var suggestionsHeaderView: ChatSuggestionsHeaderView.Type =
        ChatSuggestionsHeaderView.self
    
    /// A type for the view used as avatar when picking users to mention.
    public var mentionAvatarView: _ChatUserAvatarView<ExtraData>.Type = _ChatUserAvatarView<ExtraData>.self

    // MARK: - Current user components

    /// The view that shows current user avatar.
    public var currentUserAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type =
        _CurrentChatUserAvatarView<ExtraData>.self

    // MARK: - Navigation

    /// The navigation controller.
    public var navigationVC: NavigationVC.Type = NavigationVC.self

    /// The router responsible for navigation on channel list screen.
    public var channelListRouter: _ChatChannelListRouter<ExtraData>.Type = _ChatChannelListRouter<ExtraData>.self

    /// The router responsible for navigation on message list screen.
    public var messageListRouter: _ChatMessageListRouter<ExtraData>.Type = _ChatMessageListRouter<ExtraData>.self

    /// The router responsible for presenting alerts.
    public var alertsRouter: AlertsRouter.Type = AlertsRouter.self
    
    public init() {}
}

// MARK: - Components + Default

private var defaults: [String: Any] = [:]

public extension _Components {
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
