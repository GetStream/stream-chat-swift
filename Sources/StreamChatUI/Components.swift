//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An object containing types of UI Components that are used through the UI SDK.
public struct Components {
    /// A view that displays a title label and subtitle in a container stack view.
    public var titleContainerView: TitleContainerView.Type = TitleContainerView.self

    /// A view used as an online activity indicator (online/offline).
    public var onlineIndicatorView: (UIView & MaskProviding).Type = OnlineIndicatorView.self

    /// A view that displays the avatar image. By default a circular image.
    public var avatarView: ChatAvatarView.Type = ChatAvatarView.self

    /// An avatar view with an online indicator.
    public var presenceAvatarView: ChatPresenceAvatarView.Type = ChatPresenceAvatarView.self

    /// A `UIView` subclass which serves as container for `typingIndicator` and `UILabel` describing who is currently typing
    public var typingIndicatorView: TypingIndicatorView.Type = TypingIndicatorView.self
    
    /// A `UIView` subclass with animated 3 dots for indicating that user is typing.
    public var typingAnimationView: TypingAnimationView.Type = TypingAnimationView.self

    /// A view for inputting text with placeholder support.
    public var inputTextView: InputTextView.Type = InputTextView.self

    /// A view that displays the command name and icon.
    public var commandLabelView: CommandLabelView.Type = CommandLabelView.self

    /// A view to input content of a message.
    public var inputMessageView: InputChatMessageView.Type = InputChatMessageView.self

    /// A view that displays a quoted message.
    public var quotedMessageView: QuotedChatMessageView.Type = QuotedChatMessageView.self

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
    public var messageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver = .init()
    
    /// The view that shows a loading indicator.
    public var loadingIndicator: ChatLoadingIndicator.Type = ChatLoadingIndicator.self
    
    /// Object with set of function for handling images from CDN
    public var imageCDN: ImageCDN = StreamImageCDN()
    
    /// Object which is responsible for loading images
    public var imageLoader: ImageLoading = NukeImageLoader()
    
    /// Object responsible for providing resizing operations for `UIImage`
    public var imageProcessor: ImageProcessor = NukeImageProcessor()
    
    /// The object responsible for loading video attachments.
    public var videoLoader: VideoLoading = StreamVideoLoader()
    
    /// The view that shows a gradient.
    public var gradientView: GradientView.Type = GradientView.self
    
    /// The view that shows a playing video.
    public var playerView: PlayerView.Type = PlayerView.self

    //  MARK: -  Message List components

    /// The view controller responsible for rendering a list of messages.
    /// Used in both the Channel and Thread view controllers.
    @available(iOSApplicationExtension, unavailable)
    public var messageListVC: ChatMessageListVC.Type = ChatMessageListVC.self
    
    /// The controller that handles `ChatMessageListVC <-> ChatMessagePopUp` transition.
    public var messageActionsTransitionController: ChatMessageActionsTransitionController.Type =
        ChatMessageActionsTransitionController.self

    /// The foundation view for the message list view controller.
    public var messageListView: ChatMessageListView.Type = ChatMessageListView
        .self

    /// The view that shows the date for currently visible messages on top of message list.
    public var messageListScrollOverlayView: ChatMessageListScrollOverlayView.Type =
        ChatMessageListScrollOverlayView.self

    /// The date separator view that groups messages from the same day.
    public var messageListDateSeparatorView: ChatMessageListDateSeparatorView.Type = ChatMessageListDateSeparatorView.self

    /// A boolean value that determines wether the date overlay should be displayed while scrolling.
    public var messageListDateOverlayEnabled = true

    /// A boolean value that determines wether date separators should be shown between each message.
    public var messageListDateSeparatorEnabled = false

    /// A boolean value that determines whether the message list should use a diffable data source.
    /// Note: This is currently an experimental feature that we are actively
    /// working on and testing to make sure it is stable.
    public var _messageListDiffingEnabled = false

    /// The view controller used to perform message actions.
    public var messageActionsVC: ChatMessageActionsVC.Type = ChatMessageActionsVC.self

    /// The view controller that is presented when long-pressing a message.
    public var messagePopupVC: ChatMessagePopupVC.Type = ChatMessagePopupVC.self

    /// A view controller that renders the reaction and it's author avatar for all the reactions of a message.
    public var reactionAuthorsVC: ChatMessageReactionAuthorsVC.Type = ChatMessageReactionAuthorsVC.self

    /// A view cell that displays an individual reaction author of a message.
    public var reactionAuthorCell: ChatMessageReactionAuthorViewCell.Type = ChatMessageReactionAuthorViewCell.self

    /// The view controller used for showing the detail of a file message attachment.
    public var filePreviewVC: ChatMessageAttachmentPreviewVC.Type = ChatMessageAttachmentPreviewVC.self

    /// The view controller responsible to render image and video attachments.
    public var galleryVC: GalleryVC.Type = GalleryVC.self
    
    /// The view used to control the player for currently visible vide attachment.
    public var videoPlaybackControlView: VideoPlaybackControlView.Type =
        VideoPlaybackControlView.self
    
    /// The view used to display content of the message, i.e. in the channel detail message list.
    public var messageContentView: ChatMessageContentView.Type = ChatMessageContentView.self

    /// The view used to display a bubble around a message.
    public var messageBubbleView: ChatMessageBubbleView.Type = ChatMessageBubbleView.self

    /// The class responsible for returning the correct attachment view injector from a message
    @available(iOSApplicationExtension, unavailable)
    public var attachmentViewCatalog: AttachmentViewCatalog.Type = AttachmentViewCatalog.self

    /// The injector used to inject gallery attachment views.
    public var galleryAttachmentInjector: AttachmentViewInjector.Type = GalleryAttachmentViewInjector.self

    /// The injector used to inject link attachment views.
    @available(iOSApplicationExtension, unavailable)
    public var linkAttachmentInjector: AttachmentViewInjector.Type = LinkAttachmentViewInjector.self

    /// The injector used for injecting giphy attachment views
    public var giphyAttachmentInjector: AttachmentViewInjector.Type = GiphyAttachmentViewInjector.self

    /// The injector used for injecting file attachment views
    public var filesAttachmentInjector: AttachmentViewInjector.Type = FilesAttachmentViewInjector.self

    /// The injector used to combine multiple types of attachment views.
    /// By default, it is a combination of a file injector and a gallery injector.
    public var mixedAttachmentInjector: MixedAttachmentViewInjector.Type = MixedAttachmentViewInjector.self

    /// The button for taking an action on attachment being uploaded.
    public var attachmentActionButton: AttachmentActionButton.Type = AttachmentActionButton.self
    
    /// The view that shows error indicator in `messageContentView`.
    public var messageErrorIndicator: ChatMessageErrorIndicator.Type = ChatMessageErrorIndicator.self

    /// The view that shows message's file attachments.
    public var fileAttachmentListView: ChatMessageFileAttachmentListView
        .Type = ChatMessageFileAttachmentListView.self

    /// The view that shows a single file attachment.
    public var fileAttachmentView: ChatMessageFileAttachmentListView.ItemView.Type =
        ChatMessageFileAttachmentListView.ItemView.self
    
    /// The view that shows a link preview in message cell.
    public var linkPreviewView: ChatMessageLinkPreviewView.Type =
        ChatMessageLinkPreviewView.self
    
    /// The view that shows message's image and video attachments.
    public var galleryView: ChatMessageGalleryView.Type = ChatMessageGalleryView.self
    
    /// The view that shows an image attachment preview inside message cell.
    public var imageAttachmentGalleryPreview: ChatMessageGalleryView.ImagePreview.Type = ChatMessageGalleryView.ImagePreview.self
    
    /// The view that shows an image attachment in full-screen gallery.
    public var imageAttachmentGalleryCell: ImageAttachmentGalleryCell.Type = ImageAttachmentGalleryCell.self
    
    /// The view that shows a video attachment in full-screen gallery.
    public var videoAttachmentGalleryCell: VideoAttachmentGalleryCell.Type = VideoAttachmentGalleryCell.self
    
    /// The view that shows a video attachment preview inside a message.
    public var videoAttachmentGalleryPreview: VideoAttachmentGalleryPreview.Type = VideoAttachmentGalleryPreview.self
    
    /// The view that shows an overlay with uploading progress for image attachment that is being uploaded.
    public var imageUploadingOverlay: ChatMessageGalleryView.UploadingOverlay.Type = ChatMessageGalleryView.UploadingOverlay.self

    /// The view that shows giphy attachment with actions.
    public var giphyAttachmentView: ChatMessageInteractiveAttachmentView.Type = ChatMessageInteractiveAttachmentView.self

    /// The button that shows the attachment action.
    public var giphyActionButton: ChatMessageInteractiveAttachmentView.ActionButton.Type =
        ChatMessageInteractiveAttachmentView.ActionButton.self

    /// The view that shows a content for `.giphy` attachment.
    public var giphyView: ChatMessageGiphyView.Type = ChatMessageGiphyView.self

    /// The view that shows a badge on `giphyAttachmentView`.
    public var giphyBadgeView: ChatMessageGiphyView.GiphyBadge.Type = ChatMessageGiphyView.GiphyBadge.self
    
    /// The button that indicates unread messages at the bottom of the message list and scroll to the latest message on tap.
    public var scrollToLatestMessageButton: ScrollToLatestMessageButton.Type = ScrollToLatestMessageButton.self

    /// The view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.
    public var messageListUnreadCountView: ChatMessageListUnreadCountView.Type =
        ChatMessageListUnreadCountView.self
    
    /// The view that shows messages delivery status.
    public var messageDeliveryStatusView: ChatMessageDeliveryStatusView.Type =
        ChatMessageDeliveryStatusView.self
    
    /// The view that shows messages delivery status checkmark in channel preview and in message view.
    public var messageDeliveryStatusCheckmarkView: ChatMessageDeliveryStatusCheckmarkView.Type =
        ChatMessageDeliveryStatusCheckmarkView.self

    // MARK: - Reaction Picker components
    
    /// The Reaction picker VC.
    public var reactionPickerVC: ChatMessageReactionsVC.Type = ChatMessageReactionsVC.self

    /// The view that shows reactions bubble.
    public var reactionPickerBubbleView: ChatReactionPickerBubbleView.Type = DefaultChatReactionPickerBubbleView.self

    /// The view that shows the list of reaction toggles/buttons.
    public var reactionPickerReactionsView: ChatMessageReactionsView.Type = ChatReactionPickerReactionsView.self

    /// The view that renders a single reaction view button.
    public var reactionPickerReactionItemView: ChatMessageReactionItemView.Type = ChatMessageReactionItemView.self
    
    // MARK: - Message Reaction components

    /// The view that shows reactions of a message. This is used by the message component.
    public var messageReactionsBubbleView: ChatReactionBubbleBaseView.Type = ChatReactionsBubbleView.self

    /// The view that shows the list of reactions attached to the message.
    public var messageReactionsView: ChatMessageReactionsView.Type = ChatMessageReactionsView.self

    /// The view that renders a single reaction attached to the message.
    public var messageReactionItemView: ChatMessageReactionItemView.Type = ChatMessageReactionItemView.self

    // MARK: - Thread components

    /// The view controller used to display the detail of a message thread.
    public var threadVC: ChatThreadVC.Type = ChatThreadVC.self

    /// The view that displays channel information on the thread header.
    public var threadHeaderView: ChatThreadHeaderView.Type =
        ChatThreadHeaderView.self

    // MARK: - Channel components

    /// The view controller that contains the channel messages and represents the chat view.
    public var channelVC: ChatChannelVC.Type = ChatChannelVC.self

    /// The view that displays channel information on the channel header.
    public var channelHeaderView: ChatChannelHeaderView.Type = ChatChannelHeaderView.self

    /// The logic to generate a name for the given channel.
    @available(
        *,
        deprecated,
        message: "Please use `Appearance.default.formatters.channelName` instead"
    )
    public var channelNamer: ChatChannelNamer {
        get {
            DefaultChannelNameFormatter.channelNamer
        }
        set {
            DefaultChannelNameFormatter.channelNamer = newValue
        }
    }

    /// The collection view layout of the channel list.
    public var channelListLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

    /// The `UICollectionViewCell` subclass that shows channel information.
    public var channelCell: ChatChannelListCollectionViewCell.Type = ChatChannelListCollectionViewCell.self

    /// The channel cell separator in the channel list.
    public var channelCellSeparator: UICollectionReusableView.Type = CellSeparatorReusableView.self

    /// The view in the channel cell that shows channel actions on swipe.
    public var channelActionsView: SwipeableView.Type = SwipeableView.self
    
    /// The view that shows channel information.
    public var channelContentView: ChatChannelListItemView.Type = ChatChannelListItemView.self

    /// The view that shows a user avatar including an indicator of the user presence (online/offline).
    public var channelAvatarView: ChatChannelAvatarView.Type = ChatChannelAvatarView.self

    /// The view that shows a number of unread messages in channel.
    public var channelUnreadCountView: ChatChannelUnreadCountView.Type = ChatChannelUnreadCountView.self

    // MARK: - Composer components

    /// The view controller used to compose a message.
    public var messageComposerVC: ComposerVC.Type = ComposerVC.self

    /// The view that shows the message when it's being composed.
    public var messageComposerView: ComposerView.Type = ComposerView.self

    /// A view controller that handles the attachments.
    public var messageComposerAttachmentsVC: AttachmentsPreviewVC.Type = AttachmentsPreviewVC.self

    /// A view that holds the attachment views and provide extra functionality over them.
    public var messageComposerAttachmentCell: AttachmentPreviewContainer.Type = AttachmentPreviewContainer.self

    /// A view that displays the document attachment.
    public var messageComposerFileAttachmentView: FileAttachmentView.Type = FileAttachmentView.self

    /// A view that displays image attachment preview in composer.
    public var imageAttachmentComposerPreview: ImageAttachmentComposerPreview
        .Type = ImageAttachmentComposerPreview.self
    
    /// A view that displays the video attachment preview in composer.
    public var videoAttachmentComposerPreview: VideoAttachmentComposerPreview
        .Type = VideoAttachmentComposerPreview.self

    // MARK: - Composer suggestion components
    
    /// A view controller that shows suggestions of commands or mentions.
    public var suggestionsVC: ChatSuggestionsVC.Type = ChatSuggestionsVC.self

    /// When true the suggestionsVC will search users from the entire application instead of limit search to the current channel.
    public var mentionAllAppUsers: Bool = false

    /// The collection view of the suggestions view controller.
    public var suggestionsCollectionView: ChatSuggestionsCollectionView.Type = ChatSuggestionsCollectionView.self

    /// A view cell that displays the the suggested mention.
    public var suggestionsMentionCollectionViewCell: ChatMentionSuggestionCollectionViewCell.Type =
        ChatMentionSuggestionCollectionViewCell.self

    /// A view cell that displays the suggested command.
    public var suggestionsCommandCollectionViewCell: ChatCommandSuggestionCollectionViewCell
        .Type = ChatCommandSuggestionCollectionViewCell.self

    /// A type for view embed in cell while tagging users with @ symbol in composer.
    public var suggestionsMentionView: ChatMentionSuggestionView.Type = ChatMentionSuggestionView.self

    /// A view that displays the command name, image and arguments.
    public var suggestionsCommandView: ChatCommandSuggestionView.Type =
        ChatCommandSuggestionView.self

    /// The collection view layout of the suggestions collection view.
    public var suggestionsCollectionViewLayout: UICollectionViewLayout.Type =
        ChatSuggestionsCollectionViewLayout.self

    /// The header reusable view of the suggestion collection view.
    public var suggestionsHeaderReusableView: UICollectionReusableView.Type = ChatSuggestionsCollectionReusableView.self

    /// The header view of the suggestion collection view.
    public var suggestionsHeaderView: ChatSuggestionsHeaderView.Type =
        ChatSuggestionsHeaderView.self
    
    /// A type for the view used as avatar when picking users to mention.
    public var mentionAvatarView: ChatUserAvatarView.Type = ChatUserAvatarView.self

    // MARK: - Current user components

    /// The view that shows current user avatar.
    public var currentUserAvatarView: CurrentChatUserAvatarView.Type = CurrentChatUserAvatarView.self

    // MARK: - Navigation

    /// The navigation controller.
    public var navigationVC: NavigationVC.Type = NavigationVC.self

    /// The router responsible for navigation on channel list screen.
    @available(iOSApplicationExtension, unavailable)
    public var channelListRouter: ChatChannelListRouter.Type = ChatChannelListRouter.self

    /// The router responsible for navigation on message list screen.
    public var messageListRouter: ChatMessageListRouter.Type = ChatMessageListRouter.self

    /// The router responsible for presenting alerts.
    public var alertsRouter: AlertsRouter.Type = AlertsRouter.self
    
    public init() {}
}

// MARK: - Components + Default

public extension Components {
    static var `default` = Self()
}
