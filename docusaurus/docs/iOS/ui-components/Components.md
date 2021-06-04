
``` swift
public struct _Components<ExtraData: ExtraDataTypes> 
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

### `navigationTitleView`

The view used as a navigation bar title view for some view controllers.

``` swift
public var navigationTitleView: TitleContainerView.Type = TitleContainerView.self
```

### `createChannelButton`

A button used for creating new channels.

``` swift
public var createChannelButton: UIButton.Type = CreateChatChannelButton.self
```

### `onlineIndicatorView`

A view used as an online activity indicator (online/offline).

``` swift
public var onlineIndicatorView: (UIView & MaskProviding).Type = ChatOnlineIndicatorView.self
```

### `avatarView`

A view that displays the avatar image. By default a circular image.

``` swift
public var avatarView: ChatAvatarView.Type = ChatAvatarView.self
```

### `presenceAvatarView`

An avatar view with an online indicator.

``` swift
public var presenceAvatarView: _ChatPresenceAvatarView<ExtraData>.Type = _ChatPresenceAvatarView<ExtraData>.self
```

### `typingIndicatorView`

A `UIView` subclass which serves as container for `typingIndicator` and `UILabel` describing who is currently typing

``` swift
public var typingIndicatorView: _TypingIndicatorView<ExtraData>.Type = _TypingIndicatorView<ExtraData>.self
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
public var inputMessageView: _InputChatMessageView<ExtraData>.Type = _InputChatMessageView<ExtraData>.self
```

### `quotedMessageView`

A view that displays a quoted message.

``` swift
public var quotedMessageView: _QuotedChatMessageView<ExtraData>.Type = _QuotedChatMessageView<ExtraData>.self
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

### `checkmarkControl`

A view to check/uncheck an option.

``` swift
public var checkmarkControl: CheckboxControl.Type = CheckboxControl.self
```

### `messageLayoutOptionsResolver`

An object responsible for message layout options calculations in `ChatMessageListVC/ChatThreadVC`.

``` swift
public var messageLayoutOptionsResolver: _ChatMessageLayoutOptionsResolver<ExtraData> 
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

### `messageListVC`

The View Controller used to display content of the message, i.e. in the channel detail message list.

``` swift
public var messageListVC: _ChatMessageListVC<ExtraData>.Type = _ChatMessageListVC<ExtraData>.self
```

### `messageListCollectionView`

The collection view that shows the message list.

``` swift
public var messageListCollectionView: ChatMessageListCollectionView<ExtraData>.Type = ChatMessageListCollectionView<ExtraData>
        .self
```

### `messageListLayout`

The collection view layout used in `messageListCollectionView`.

``` swift
public var messageListLayout: ChatMessageListCollectionViewLayout.Type = ChatMessageListCollectionViewLayout.self
```

### `messageListScrollOverlayView`

The view that shows the date for currently visible messages on top of message list.

``` swift
public var messageListScrollOverlayView: ChatMessageListScrollOverlayView.Type = ChatMessageListScrollOverlayView.self
```

### `threadVC`

The View Controller used to display the detail of a message thread.

``` swift
public var threadVC: _ChatThreadVC<ExtraData>.Type = _ChatThreadVC<ExtraData>.self
```

### `messagePopupVC`

The View Controller by default used to display long-press menu of the message.

``` swift
public var messagePopupVC: _ChatMessagePopupVC<ExtraData>.Type = _ChatMessagePopupVC<ExtraData>.self
```

### `filePreviewVC`

The View Controller used for showing detail of a file message attachment.

``` swift
public var filePreviewVC: ChatMessageAttachmentPreviewVC.Type = ChatMessageAttachmentPreviewVC.self
```

### `imagePreviewVC`

The View Controller used for showing detail of an image message attachment.

``` swift
public var imagePreviewVC: _ImageGalleryVC<ExtraData>.Type = _ImageGalleryVC<ExtraData>.self
```

### `messageContentView`

The view used to display content of the message, i.e. in the channel detail message list.

``` swift
public var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self
```

### `messageBubbleView`

The view used to display a bubble around a message.

``` swift
public var messageBubbleView: _ChatMessageBubbleView<ExtraData>.Type = _ChatMessageBubbleView<ExtraData>.self
```

### `galleryAttachmentInjector`

The injector used to inject gallery attachment views.

``` swift
public var galleryAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GalleryAttachmentViewInjector<ExtraData>.self
```

### `linkAttachmentInjector`

The injector used to inject link attachment views.

``` swift
public var linkAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _LinkAttachmentViewInjector<ExtraData>.self
```

### `giphyAttachmentInjector`

The injector used for injecting giphy attachment views

``` swift
public var giphyAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GiphyAttachmentViewInjector<ExtraData>.self
```

### `filesAttachmentInjector`

The injector used for injecting file attachment views

``` swift
public var filesAttachmentInjector: _FilesAttachmentViewInjector<ExtraData>.Type = _FilesAttachmentViewInjector<ExtraData>.self
```

### `reactionsBubbleView`

The view that shows reactions bubble.

``` swift
public var reactionsBubbleView: _ChatMessageReactionsBubbleView<ExtraData>.Type =
        _ChatMessageDefaultReactionsBubbleView<ExtraData>.self
```

### `reactionsView`

The view that shows reactions list in a bubble.

``` swift
public var reactionsView: _ChatMessageReactionsView<ExtraData>.Type = _ChatMessageReactionsView<ExtraData>.self
```

### `reactionItemView`

The view that shows a single reaction.

``` swift
public var reactionItemView: _ChatMessageReactionsView<ExtraData>.ItemView.Type =
        _ChatMessageReactionsView<ExtraData>.ItemView.self
```

### `messageErrorIndicator`

The view that shows error indicator in `messageContentView`.

``` swift
public var messageErrorIndicator: ChatMessageErrorIndicator.Type = ChatMessageErrorIndicator.self
```

### `fileAttachmentListView`

The view that shows message's file attachments.

``` swift
public var fileAttachmentListView: _ChatMessageFileAttachmentListView<ExtraData>
        .Type = _ChatMessageFileAttachmentListView<ExtraData>.self
```

### `fileAttachmentView`

The view that shows a single file attachment.

``` swift
public var fileAttachmentView: _ChatMessageFileAttachmentListView<ExtraData>.ItemView.Type =
        _ChatMessageFileAttachmentListView<ExtraData>.ItemView.self
```

### `imageGalleryView`

The view that shows message's image attachments.

``` swift
public var imageGalleryView: _ChatMessageImageGallery<ExtraData>.Type =
        _ChatMessageImageGallery<ExtraData>.self
```

### `imageUploadingOverlay`

The view that shows an overlay with uploading progress for image attachment that is being uploaded.

``` swift
public var imageUploadingOverlay: _ChatMessageImageGallery<ExtraData>.UploadingOverlay.Type =
        _ChatMessageImageGallery<ExtraData>.UploadingOverlay.self
```

### `giphyAttachmentView`

The view that shows giphy attachment with actions.

``` swift
public var giphyAttachmentView: _ChatMessageInteractiveAttachmentView<ExtraData>.Type =
        _ChatMessageInteractiveAttachmentView<ExtraData>.self
```

### `giphyActionButton`

The button that shows the attachment action.

``` swift
public var giphyActionButton: _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
        _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self
```

### `giphyView`

The view that shows a content for `.giphy` attachment.

``` swift
public var giphyView: _ChatMessageGiphyView<ExtraData>.Type =
        _ChatMessageGiphyView<ExtraData>.self
```

### `giphyBadgeView`

The view that shows a badge on `giphyAttachmentView`.

``` swift
public var giphyBadgeView: _ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = _ChatMessageGiphyView<ExtraData>.GiphyBadge.self
```

### `scrollToLatestMessageButton`

The button that indicates unread messages at the bottom of the message list and scroll to the latest message on tap.

``` swift
public var scrollToLatestMessageButton: UIButton.Type = ScrollToLatestMessageButton.self
```

### `channelNamer`

The logic to generate a name for the given channel.

``` swift
public var channelNamer: ChatChannelNamer<ExtraData> 
```

### `channelListLayout`

The collection view layout of the channel list.

``` swift
public var channelListLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self
```

### `channelCell`

The `UICollectionViewCell` subclass that shows channel information.

``` swift
public var channelCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
        _ChatChannelListCollectionViewCell<ExtraData>.self
```

### `channelCellSeparator`

The channel cell separator in the channel list.

``` swift
public var channelCellSeparator: UICollectionReusableView.Type = CellSeparatorReusableView.self
```

### `channelActionsView`

The view in the channel cell that shows channel actions on swipe.

``` swift
public var channelActionsView: _SwipeableView<ExtraData>.Type =
        _SwipeableView<ExtraData>.self
```

### `channelContentView`

The view that shows channel information.

``` swift
public var channelContentView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self
```

### `channelAvatarView`

The view that shows a user avatar including an indicator of the user presence (online/offline).

``` swift
public var channelAvatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self
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
public var messageComposerVC: _ComposerVC<ExtraData>.Type =
        _ComposerVC<ExtraData>.self
```

### `messageComposerView`

The view that shows the message when it's being composed.

``` swift
public var messageComposerView: _ComposerView<ExtraData>.Type =
        _ComposerView<ExtraData>.self
```

### `messageComposerAttachmentsVC`

A view controller that handles the attachments.

``` swift
public var messageComposerAttachmentsVC: _AttachmentsPreviewVC<ExtraData>.Type =
        _AttachmentsPreviewVC<ExtraData>.self
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

### `messageComposerImageAttachmentView`

A view that displays the image attachment.

``` swift
public var messageComposerImageAttachmentView: _ImageAttachmentView<ExtraData>.Type = _ImageAttachmentView<ExtraData>.self
```

### `suggestionsVC`

A view controller that shows suggestions of commands or mentions.

``` swift
public var suggestionsVC: _ChatSuggestionsViewController<ExtraData>.Type =
        _ChatSuggestionsViewController<ExtraData>.self
```

### `suggestionsCollectionView`

The collection view of the suggestions view controller.

``` swift
public var suggestionsCollectionView: _ChatSuggestionsCollectionView<ExtraData>.Type =
        _ChatSuggestionsCollectionView<ExtraData>.self
```

### `suggestionsMentionCollectionViewCell`

A view cell that displays the the suggested mention.

``` swift
public var suggestionsMentionCollectionViewCell: _ChatMentionSuggestionCollectionViewCell<ExtraData>.Type =
        _ChatMentionSuggestionCollectionViewCell<ExtraData>.self
```

### `suggestionsCommandCollectionViewCell`

A view cell that displays the suggested command.

``` swift
public var suggestionsCommandCollectionViewCell: _ChatCommandSuggestionCollectionViewCell<ExtraData>.Type =
        _ChatCommandSuggestionCollectionViewCell<ExtraData>.self
```

### `suggestionsMentionCellView`

A type for view embed in cell while tagging users with @ symbol in composer.

``` swift
public var suggestionsMentionCellView: _ChatMentionSuggestionView<ExtraData>.Type =
        _ChatMentionSuggestionView<ExtraData>.self
```

### `suggestionsCommandCellView`

A view that displays the command name, image and arguments.

``` swift
public var suggestionsCommandCellView: ChatCommandSuggestionView.Type =
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
public var suggestionsHeaderReusableView: UICollectionReusableView.Type =
        _ChatSuggestionsCollectionReusableView<ExtraData>.self
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
public var mentionAvatarView: _ChatUserAvatarView<ExtraData>.Type = _ChatUserAvatarView<ExtraData>.self
```

### `currentUserAvatarView`

The view that shows current user avatar.

``` swift
public var currentUserAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type =
        _CurrentChatUserAvatarView<ExtraData>.self
```

### `navigationVC`

The navigation controller.

``` swift
public var navigationVC: NavigationVC.Type = NavigationVC.self
```

### `channelListRouter`

The router responsible for navigation on channel list screen.

``` swift
public var channelListRouter: _ChatChannelListRouter<ExtraData>.Type = _ChatChannelListRouter<ExtraData>.self
```

### `messageListRouter`

The router responsible for navigation on message list screen.

``` swift
public var messageListRouter: _ChatMessageListRouter<ExtraData>.Type = _ChatMessageListRouter<ExtraData>.self
```

### `alertsRouter`

The router responsible for presenting alerts.

``` swift
public var alertsRouter: AlertsRouter.Type = AlertsRouter.self
```

### `` `default` ``

``` swift
static var `default`: Self 
```
