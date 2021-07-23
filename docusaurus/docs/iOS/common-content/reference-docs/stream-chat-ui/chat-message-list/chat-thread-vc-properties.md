
### `channelController`

Controller for observing data changes within the channel

``` swift
open var channelController: _ChatChannelController<ExtraData>!
```

### `messageController`

Controller for observing data changes within the parent thread message.

``` swift
open var messageController: _ChatMessageController<ExtraData>!
```

### `keyboardObserver`

Observer responsible for setting the correct offset when keyboard frame is changed

``` swift
open lazy var keyboardObserver 
```

### `userSuggestionSearchController`

User search controller passed directly to the composer

``` swift
open lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> 
```

### `listView`

View used to display the messages

``` swift
open private(set) lazy var listView: _ChatMessageListView<ExtraData> 
```

### `dateOverlayView`

View used to display date of currently displayed messages

``` swift
open private(set) lazy var dateOverlayView: ChatMessageListScrollOverlayView 
```

### `messageComposerVC`

Controller that handles the composer view

``` swift
open private(set) lazy var messageComposerVC 
```

### `titleView`

A view that displays a title label and subtitle in a container stack view.

``` swift
open lazy var titleView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints
```

### `router`

Handles navigation actions from messages

``` swift
open lazy var router 
```

### `messages`

``` swift
public var messages: [_ChatMessage<ExtraData>] 
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `viewDidLoad()`

``` swift
override open func viewDidLoad() 
```

### `viewDidAppear(_:)`

``` swift
override open func viewDidAppear(_ animated: Bool) 
```

### `viewDidDisappear(_:)`

``` swift
override open func viewDidDisappear(_ animated: Bool) 
```

### `traitCollectionDidChange(_:)`

``` swift
override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) 
```

### `cellContentClassForMessage(at:)`

Returns the content view class for the message at given `indexPath`

``` swift
open func cellContentClassForMessage(at indexPath: IndexPath) -> _ChatMessageContentView<ExtraData>.Type 
```

### `attachmentViewInjectorClassForMessage(at:)`

Returns the attachment view injector class for the message at given `indexPath`

``` swift
open func attachmentViewInjectorClassForMessage(
        at indexPath: IndexPath
    ) -> _AttachmentViewInjector<ExtraData>.Type? 
```

### `attachmentViewInjectorClass(for:)`

Returns the attachment view injector class for the message at given `ChatMessage`

``` swift
open func attachmentViewInjectorClass(for message: _ChatMessage<ExtraData>) -> _AttachmentViewInjector<ExtraData>.Type? 
```

### `cellLayoutOptionsForMessage(at:)`

Returns layout options for the message on given `indexPath`.

``` swift
open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions 
```

Layout options are used to determine the layout of the message.
By default there is one message with all possible layout and layout options
determines which parts of the message are visible for the given message.

### `cellLayoutOptionsForMessage(at:messages:)`

``` swift
open func cellLayoutOptionsForMessage(
        at indexPath: IndexPath,
        messages: AnyRandomAccessCollection<_ChatMessage<ExtraData>>
    ) -> ChatMessageLayoutOptions 
```

### `numberOfSections(in:)`

``` swift
open func numberOfSections(in tableView: UITableView) -> Int 
```

### `tableView(_:numberOfRowsInSection:)`

``` swift
open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int 
```

### `tableView(_:cellForRowAt:)`

``` swift
open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell 
```

### `tableView(_:willDisplay:forRowAt:)`

``` swift
open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) 
```

### `scrollToMostRecentMessage(animated:)`

Scrolls to most recent message

``` swift
open func scrollToMostRecentMessage(animated: Bool = true) 
```

### `updateNavigationTitle()`

Updates the status data in `titleView`.

``` swift
open func updateNavigationTitle() 
```

For group chat is called every-time the channel changes.

### `handleLongPress(_:)`

Handles long press action on collection view.

``` swift
@objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) 
```

Default implementation will convert the gesture location to collection view's `indexPath`
and then call selection action on the selected cell.

### `handleTap(_:)`

Handles tap action on the table view.

``` swift
@objc open func handleTap(_ gesture: UITapGestureRecognizer) 
```

Default implementation will dismiss the keyboard if it is open

### `updateMessages(with:completion:)`

Updates the collection view data with given `changes`.

``` swift
open func updateMessages(with changes: [ListChange<_ChatMessage<ExtraData>>], completion: (() -> Void)? = nil) 
```

### `didSelectMessageCell(at:)`

Presents custom actions controller with all possible actions with the selected message.

``` swift
open func didSelectMessageCell(at indexPath: IndexPath) 
```

### `restartUploading(for:)`

Restarts upload of given `attachment` in case of failure

``` swift
open func restartUploading(for attachmentId: AttachmentId) 
```

### `didTapOnAttachmentAction(_:at:)`

Executes the provided action on the message

``` swift
open func didTapOnAttachmentAction(
        _ action: AttachmentAction,
        at indexPath: IndexPath
    ) 
```

### `didTapOnLinkAttachment(_:at:)`

``` swift
open func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath?
    ) 
```

### `didTapOnAttachment(_:at:)`

``` swift
open func didTapOnAttachment(
        _ attachment: ChatMessageFileAttachment,
        at indexPath: IndexPath?
    ) 
```

### `composerDidCreateNewMessage()`

``` swift
open func composerDidCreateNewMessage() 
```

### `channelController(_:didUpdateChannel:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) 
```

### `messageController(_:didChangeMessage:)`

``` swift
public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) 
```

### `messageController(_:didChangeReplies:)`

``` swift
open func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
```

### `chatMessageActionsVC(_:message:didTapOnActionItem:)`

``` swift
open func chatMessageActionsVC(
        _ vc: _ChatMessageActionsVC<ExtraData>,
        message: _ChatMessage<ExtraData>,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) 
```

### `chatMessageActionsVCDidFinish(_:)`

``` swift
open func chatMessageActionsVCDidFinish(
        _ vc: _ChatMessageActionsVC<ExtraData>
    ) 
```

### `messageContentViewDidTapOnErrorIndicator(_:)`

``` swift
open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) 
```

### `messageContentViewDidTapOnThread(_:)`

``` swift
open func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) 
```

### `messageContentViewDidTapOnQuotedMessage(_:)`

``` swift
open func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) 
```

### `galleryMessageContentView(at:didTapAttachmentPreview:previews:)`

``` swift
open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTapAttachmentPreview attachmentId: AttachmentId,
        previews: [GalleryItemPreview]
    ) 
```

### `galleryMessageContentView(at:didTakeActionOnUploadingAttachment:)`

``` swift
open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTakeActionOnUploadingAttachment attachmentId: AttachmentId
    ) 
```

### `messageForIndexPath(_:)`

``` swift
open func messageForIndexPath(_ indexPath: IndexPath) -> _ChatMessage<ExtraData> 
```

### `scrollOverlay(_:textForItemAt:)`

``` swift
open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? 
```

### `gestureRecognizer(_:shouldReceive:)`

``` swift
open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool 
