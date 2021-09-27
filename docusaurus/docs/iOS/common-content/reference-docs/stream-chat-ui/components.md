---
title: Components
---

An object containing types of UI Components that are used through the UI SDK.

``` swift
public struct Components 
```

## Initializers

### `init()`

``` swift
public init() 
```

## Properties

### `asObservableObject`

Used to initialize `_Components` as `ObservableObject`.

``` swift
public var asObservableObject: ObservableObject 
```

### `titleContainerView`

A view that displays a title label and subtitle in a container stack view.

``` swift
public var titleContainerView: TitleContainerView.Type = TitleContainerView.self
```

### `onlineIndicatorView`

A view used as an online activity indicator (online/offline).

``` swift
public var onlineIndicatorView: (UIView & MaskProviding).Type = OnlineIndicatorView.self
```

### `avatarView`

A view that displays the avatar image. By default a circular image.

``` swift
public var avatarView: ChatAvatarView.Type = ChatAvatarView.self
```

### `presenceAvatarView`

An avatar view with an online indicator.

``` swift
public var presenceAvatarView: ChatPresenceAvatarView.Type = ChatPresenceAvatarView.self
```

### `typingIndicatorView`

A `UIView` subclass which serves as container for `typingIndicator` and `UILabel` describing who is currently typing

``` swift
public var typingIndicatorView: TypingIndicatorView.Type = TypingIndicatorView.self
```

### `typingAnimationView`

A `UIView` subclass with animated 3 dots for indicating that user is typing.

``` swift
public var typingAnimationView: TypingAnimationView.Type = TypingAnimationView.self
```

### `inputTextView`

A view for inputting text with placeholder support.

``` swift
public var inputTextView: InputTextView.Type = InputTextView.self
```

### `commandLabelView`

A view that displays the command name and icon.

``` swift
public var commandLabelView: CommandLabelView.Type = CommandLabelView.self
```

### `inputMessageView`

A view to input content of a message.

``` swift
public var inputMessageView: InputChatMessageView.Type = InputChatMessageView.self
```

### `quotedMessageView`

A view that displays a quoted message.

``` swift
public var quotedMessageView: QuotedChatMessageView.Type = QuotedChatMessageView.self
```

### `sendButton`

A button used for sending a message, or any type of content.

``` swift
public var sendButton: UIButton.Type = SendButton.self
```

### `confirmButton`

A button for confirming actions.

``` swift
public var confirmButton: UIButton.Type = ConfirmButton.self
```

### `attachmentButton`

A button for opening attachments.

``` swift
public var attachmentButton: UIButton.Type = AttachmentButton.self
```

### `attachmentPreviewViewPlaceholder`

A view used as a fallback preview view for attachments that don't confirm to `AttachmentPreviewProvider`

``` swift
public var attachmentPreviewViewPlaceholder: UIView.Type = AttachmentPlaceholderView.self
```

### `commandsButton`

A button for opening commands.

``` swift
public var commandsButton: UIButton.Type = CommandButton.self
```

### `shrinkInputButton`

A button for shrinking the input view to allow more space for other actions.

``` swift
public var shrinkInputButton: UIButton.Type = ShrinkInputButton.self
```

### `closeButton`

A button for closing, dismissing or clearing information.

``` swift
public var closeButton: UIButton.Type = CloseButton.self
```

### `shareButton`

A button for sharing an information.

``` swift
public var shareButton: UIButton.Type = ShareButton.self
```

### `checkmarkControl`

A view to check/uncheck an option.

``` swift
public var checkmarkControl: CheckboxControl.Type = CheckboxControl.self
```

### `messageLayoutOptionsResolver`

An object responsible for message layout options calculations in `ChatMessageListVC/ChatThreadVC`.

``` swift
public var messageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver 
```

### `loadingIndicator`

The view that shows a loading indicator.

``` swift
public var loadingIndicator: ChatLoadingIndicator.Type = ChatLoadingIndicator.self
```

### `imageCDN`

Object with set of function for handling images from CDN

``` swift
public var imageCDN: ImageCDN 
```

### `imageLoader`

Object which is responsible for loading images

``` swift
public var imageLoader: ImageLoading 
```

### `imageProcessor`

Object responsible for providing resizing operations for `UIImage`

``` swift
public var imageProcessor: ImageProcessor 
```

### `videoPreviewLoader`

The object that loads previews for video attachments.

``` swift
public var videoPreviewLoader: VideoPreviewLoader 
```

### `gradientView`

The view that shows a gradient.

``` swift
public var gradientView: GradientView.Type = GradientView.self
```

### `playerView`

The view that shows a playing video.

``` swift
public var playerView: PlayerView.Type = PlayerView.self
```

### `messageListVC`

The View Controller used to display content of the message, i.e. in the channel detail message list.

``` swift
@available(iOSApplicationExtension, unavailable)
    public var messageListVC: ChatMessageListVC.Type = ChatMessageListVC.self
```

### `messageListView`

The view that shows the message list.

``` swift
public var messageListView: ChatMessageListView.Type = ChatMessageListView
        .self
```

### `messageListScrollOverlayView`

The view that shows the date for currently visible messages on top of message list.

``` swift
public var messageListScrollOverlayView: ChatMessageListScrollOverlayView.Type =
        ChatMessageListScrollOverlayView.self
```

### `messageActionsVC`

The View Controller by default used to display message actions after long-pressing on the message.

``` swift
public var messageActionsVC: ChatMessageActionsVC.Type = ChatMessageActionsVC.self
```

### `messageReactionsVC`

The View Controller by default used to display interactive reactions view after long-pressing on the message.

``` swift
public var messageReactionsVC: ChatMessageReactionsVC.Type = ChatMessageReactionsVC.self
```

### `messagePopupVC`

The View Controller by default used to display long-press menu of the message.

``` swift
public var messagePopupVC: ChatMessagePopupVC.Type = ChatMessagePopupVC.self
```

### `filePreviewVC`

The View Controller used for showing detail of a file message attachment.

``` swift
public var filePreviewVC: ChatMessageAttachmentPreviewVC.Type = ChatMessageAttachmentPreviewVC.self
```

### `galleryVC`

The View Controller used for show image and video attachments.

``` swift
public var galleryVC: GalleryVC.Type = GalleryVC.self
```

### `videoPlaybackControlView`

The view used to control the player for currently visible vide attachment.

``` swift
public var videoPlaybackControlView: VideoPlaybackControlView.Type =
        VideoPlaybackControlView.self
```

### `messageContentView`

The view used to display content of the message, i.e. in the channel detail message list.

``` swift
public var messageContentView: ChatMessageContentView.Type = ChatMessageContentView.self
```

### `messageBubbleView`

The view used to display a bubble around a message.

``` swift
public var messageBubbleView: ChatMessageBubbleView.Type = ChatMessageBubbleView.self
```

### `attachmentViewCatalog`

The class responsible for returning the correct attachment view injector from a message

``` swift
@available(iOSApplicationExtension, unavailable)
    public var attachmentViewCatalog: AttachmentViewCatalog.Type = AttachmentViewCatalog.self
```

### `galleryAttachmentInjector`

The injector used to inject gallery attachment views.

``` swift
public var galleryAttachmentInjector: AttachmentViewInjector.Type = GalleryAttachmentViewInjector.self
```

### `linkAttachmentInjector`

The injector used to inject link attachment views.

``` swift
@available(iOSApplicationExtension, unavailable)
    public var linkAttachmentInjector: AttachmentViewInjector.Type = LinkAttachmentViewInjector.self
```

### `giphyAttachmentInjector`

The injector used for injecting giphy attachment views

``` swift
public var giphyAttachmentInjector: AttachmentViewInjector.Type = GiphyAttachmentViewInjector.self
```

### `filesAttachmentInjector`

The injector used for injecting file attachment views

``` swift
public var filesAttachmentInjector: AttachmentViewInjector.Type = FilesAttachmentViewInjector.self
```

### `reactionsBubbleView`

The view that shows reactions bubble.

``` swift
public var reactionsBubbleView: ChatMessageReactionsBubbleView.Type = ChatMessageDefaultReactionsBubbleView.self
```

### `attachmentActionButton`

The button for taking an action on attachment being uploaded.

``` swift
public var attachmentActionButton: AttachmentActionButton.Type = AttachmentActionButton.self
```

### `reactionsView`

The view that shows reactions list in a bubble.

``` swift
public var reactionsView: ChatMessageReactionsView.Type = ChatMessageReactionsView.self
```

### `reactionItemView`

The view that shows a single reaction.

``` swift
public var reactionItemView: ChatMessageReactionsView.ItemView.Type = ChatMessageReactionsView.ItemView.self
```

### `messageErrorIndicator`

The view that shows error indicator in `messageContentView`.

``` swift
public var messageErrorIndicator: ChatMessageErrorIndicator.Type = ChatMessageErrorIndicator.self
```

### `fileAttachmentListView`

The view that shows message's file attachments.

``` swift
public var fileAttachmentListView: ChatMessageFileAttachmentListView
        .Type = ChatMessageFileAttachmentListView.self
```

### `fileAttachmentView`

The view that shows a single file attachment.

``` swift
public var fileAttachmentView: ChatMessageFileAttachmentListView.ItemView.Type =
        ChatMessageFileAttachmentListView.ItemView.self
```

### `linkPreviewView`

The view that shows a link preview in message cell.

``` swift
public var linkPreviewView: ChatMessageLinkPreviewView.Type =
        ChatMessageLinkPreviewView.self
```

### `galleryView`

The view that shows message's image and video attachments.

``` swift
public var galleryView: ChatMessageGalleryView.Type = ChatMessageGalleryView.self
```

### `imageAttachmentGalleryPreview`

The view that shows an image attachment preview inside message cell.

``` swift
public var imageAttachmentGalleryPreview: ChatMessageGalleryView.ImagePreview.Type = ChatMessageGalleryView.ImagePreview.self
```

### `videoAttachmentGalleryCell`

The view that shows a video attachment in full-screen gallery.

``` swift
public var videoAttachmentGalleryCell: VideoAttachmentGalleryCell.Type = VideoAttachmentGalleryCell.self
```

### `videoAttachmentGalleryPreview`

The view that shows a video attachment preview inside a message.

``` swift
public var videoAttachmentGalleryPreview: VideoAttachmentGalleryPreview.Type = VideoAttachmentGalleryPreview.self
```

### `imageUploadingOverlay`

The view that shows an overlay with uploading progress for image attachment that is being uploaded.

``` swift
public var imageUploadingOverlay: ChatMessageGalleryView.UploadingOverlay.Type = ChatMessageGalleryView.UploadingOverlay.self
```

### `giphyAttachmentView`

The view that shows giphy attachment with actions.

``` swift
public var giphyAttachmentView: ChatMessageInteractiveAttachmentView.Type = ChatMessageInteractiveAttachmentView.self
```

### `giphyActionButton`

The button that shows the attachment action.

``` swift
public var giphyActionButton: ChatMessageInteractiveAttachmentView.ActionButton.Type =
        ChatMessageInteractiveAttachmentView.ActionButton.self
```

### `giphyView`

The view that shows a content for `.giphy` attachment.

``` swift
public var giphyView: ChatMessageGiphyView.Type = ChatMessageGiphyView.self
```

### `giphyBadgeView`

The view that shows a badge on `giphyAttachmentView`.

``` swift
public var giphyBadgeView: ChatMessageGiphyView.GiphyBadge.Type = ChatMessageGiphyView.GiphyBadge.self
```

### `scrollToLatestMessageButton`

The button that indicates unread messages at the bottom of the message list and scroll to the latest message on tap.

``` swift
public var scrollToLatestMessageButton: ScrollToLatestMessageButton.Type = ScrollToLatestMessageButton.self
```

### `messageListUnreadCountView`

The view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.

``` swift
public var messageListUnreadCountView: ChatMessageListUnreadCountView.Type =
        ChatMessageListUnreadCountView.self
```

### `chatReactionsBubbleView`

The view that corresponds to container of Reactions for Message

``` swift
public var chatReactionsBubbleView: ChatReactionsBubbleView.Type =
        ChatReactionsBubbleView.self
```

### `threadVC`

The View Controller used to display the detail of a message thread.

``` swift
public var threadVC: ChatThreadVC.Type = ChatThreadVC.self
```

### `threadHeaderView`

The view that displays channel information on the thread header.

``` swift
public var threadHeaderView: ChatThreadHeaderView.Type =
        ChatThreadHeaderView.self
```

### `channelVC`

The view controller that contains the channel messages and represents the chat view.

``` swift
public var channelVC: ChatChannelVC.Type = ChatChannelVC.self
```

### `channelHeaderView`

The view that displays channel information on the channel header.

``` swift
public var channelHeaderView: ChatChannelHeaderView.Type = ChatChannelHeaderView.self
```

### `channelNamer`

The logic to generate a name for the given channel.

``` swift
public var channelNamer: ChatChannelNamer 
```

### `channelListLayout`

The collection view layout of the channel list.

``` swift
public var channelListLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self
```

### `channelCell`

The `UICollectionViewCell` subclass that shows channel information.

``` swift
public var channelCell: ChatChannelListCollectionViewCell.Type = ChatChannelListCollectionViewCell.self
```

### `channelCellSeparator`

The channel cell separator in the channel list.

``` swift
public var channelCellSeparator: UICollectionReusableView.Type = CellSeparatorReusableView.self
```

### `channelActionsView`

The view in the channel cell that shows channel actions on swipe.

``` swift
public var channelActionsView: SwipeableView.Type = SwipeableView.self
```

### `channelContentView`

The view that shows channel information.

``` swift
public var channelContentView: ChatChannelListItemView.Type = ChatChannelListItemView.self
```

### `channelAvatarView`

The view that shows a user avatar including an indicator of the user presence (online/offline).

``` swift
public var channelAvatarView: ChatChannelAvatarView.Type = ChatChannelAvatarView.self
```

### `channelUnreadCountView`

The view that shows a number of unread messages in channel.

``` swift
public var channelUnreadCountView: ChatChannelUnreadCountView.Type = ChatChannelUnreadCountView.self
```

### `channelReadStatusView`

The view that shows a read/unread status of the last message in channel.

``` swift
public var channelReadStatusView: ChatChannelReadStatusCheckmarkView.Type =
        ChatChannelReadStatusCheckmarkView.self
```

### `messageComposerVC`

The view controller used to compose a message.

``` swift
public var messageComposerVC: ComposerVC.Type = ComposerVC.self
```

### `messageComposerView`

The view that shows the message when it's being composed.

``` swift
public var messageComposerView: ComposerView.Type = ComposerView.self
```

### `messageComposerAttachmentsVC`

A view controller that handles the attachments.

``` swift
public var messageComposerAttachmentsVC: AttachmentsPreviewVC.Type = AttachmentsPreviewVC.self
```

### `messageComposerAttachmentCell`

A view that holds the attachment views and provide extra functionality over them.

``` swift
public var messageComposerAttachmentCell: AttachmentPreviewContainer.Type = AttachmentPreviewContainer.self
```

### `messageComposerFileAttachmentView`

A view that displays the document attachment.

``` swift
public var messageComposerFileAttachmentView: FileAttachmentView.Type = FileAttachmentView.self
```

### `imageAttachmentComposerPreview`

A view that displays image attachment preview in composer.

``` swift
public var imageAttachmentComposerPreview: ImageAttachmentComposerPreview
        .Type = ImageAttachmentComposerPreview.self
```

### `videoAttachmentComposerPreview`

A view that displays the video attachment preview in composer.

``` swift
public var videoAttachmentComposerPreview: VideoAttachmentComposerPreview
        .Type = VideoAttachmentComposerPreview.self
```

### `suggestionsVC`

A view controller that shows suggestions of commands or mentions.

``` swift
public var suggestionsVC: ChatSuggestionsVC.Type = ChatSuggestionsVC.self
```

### `mentionAllAppUsers`

When true the suggestionsVC will search users from the entire application instead of limit search to the current channel.

``` swift
public var mentionAllAppUsers: Bool = false
```

### `suggestionsCollectionView`

The collection view of the suggestions view controller.

``` swift
public var suggestionsCollectionView: ChatSuggestionsCollectionView.Type = ChatSuggestionsCollectionView.self
```

### `suggestionsMentionCollectionViewCell`

A view cell that displays the the suggested mention.

``` swift
public var suggestionsMentionCollectionViewCell: ChatMentionSuggestionCollectionViewCell.Type =
        ChatMentionSuggestionCollectionViewCell.self
```

### `suggestionsCommandCollectionViewCell`

A view cell that displays the suggested command.

``` swift
public var suggestionsCommandCollectionViewCell: ChatCommandSuggestionCollectionViewCell
        .Type = ChatCommandSuggestionCollectionViewCell.self
```

### `suggestionsMentionView`

A type for view embed in cell while tagging users with @ symbol in composer.

``` swift
public var suggestionsMentionView: ChatMentionSuggestionView.Type = ChatMentionSuggestionView.self
```

### `suggestionsCommandView`

A view that displays the command name, image and arguments.

``` swift
public var suggestionsCommandView: ChatCommandSuggestionView.Type =
        ChatCommandSuggestionView.self
```

### `suggestionsCollectionViewLayout`

The collection view layout of the suggestions collection view.

``` swift
public var suggestionsCollectionViewLayout: UICollectionViewLayout.Type =
        ChatSuggestionsCollectionViewLayout.self
```

### `suggestionsHeaderReusableView`

The header reusable view of the suggestion collection view.

``` swift
public var suggestionsHeaderReusableView: UICollectionReusableView.Type = ChatSuggestionsCollectionReusableView.self
```

### `suggestionsHeaderView`

The header view of the suggestion collection view.

``` swift
public var suggestionsHeaderView: ChatSuggestionsHeaderView.Type =
        ChatSuggestionsHeaderView.self
```

### `mentionAvatarView`

A type for the view used as avatar when picking users to mention.

``` swift
public var mentionAvatarView: ChatUserAvatarView.Type = ChatUserAvatarView.self
```

### `currentUserAvatarView`

The view that shows current user avatar.

``` swift
public var currentUserAvatarView: CurrentChatUserAvatarView.Type = CurrentChatUserAvatarView.self
```

### `navigationVC`

The navigation controller.

``` swift
public var navigationVC: NavigationVC.Type = NavigationVC.self
```

### `channelListRouter`

The router responsible for navigation on channel list screen.

``` swift
@available(iOSApplicationExtension, unavailable)
    public var channelListRouter: ChatChannelListRouter.Type = ChatChannelListRouter.self
```

### `messageListRouter`

The router responsible for navigation on message list screen.

``` swift
public var messageListRouter: ChatMessageListRouter.Type = ChatMessageListRouter.self
```

### `alertsRouter`

The router responsible for presenting alerts.

``` swift
public var alertsRouter: AlertsRouter.Type = AlertsRouter.self
```

### `` `default` ``

``` swift
static var `default` 
```
