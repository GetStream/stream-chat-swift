---
title: ChatMessageListVC
---

Controller that shows list of messages and composer together in the selected channel.

``` swift
open class _ChatMessageListVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    ThemeProvider,
    ComposerVCDelegate,
    _ChatChannelControllerDelegate,
    _ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    UITableViewDelegate,
    UITableViewDataSource,
    UIGestureRecognizerDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    LinkPreviewViewDelegate,
    FileActionContentViewDelegate,
    ChatMessageListScrollOverlayDataSource 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), [`FileActionContentViewDelegate`](../attachments/file-action-content-view-delegate), [`GalleryContentViewDelegate`](../attachments/gallery-content-view-delegate), [`GiphyActionContentViewDelegate`](../attachments/giphy-action-content-view-delegate), [`LinkPreviewViewDelegate`](../attachments/link-preview-view-delegate), [`ChatMessageContentViewDelegate`](../chat-message/chat-message-content-view-delegate), [`ChatMessageListScrollOverlayDataSource`](../chat-message-list-scroll-overlay-data-source), [`SwiftUIRepresentable`](../../common-views/swift-ui-representable), [`ComposerVCDelegate`](../../composer/composer-vc-delegate), [`ThemeProvider`](../../utils/theme-provider), `UIGestureRecognizerDelegate`, `UITableViewDataSource`, `UITableViewDelegate`, `_ChatChannelControllerDelegate`, [`_ChatMessageActionsVCDelegate`](../../message-actions-popup/chat-message-actions-vc-delegate)

## Properties

### `content`

``` swift
public var content: _ChatChannelController<ExtraData> 
```

### `channelController`

Controller for observing data changes within the channel

``` swift
open var channelController: _ChatChannelController<ExtraData>!
```

### `client`

``` swift
public var client: _ChatClient<ExtraData> 
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

### `headerView`

The header view of the message list that by default is the titleView of the navigation bar.

``` swift
open private(set) lazy var headerView: _ChatMessageListHeaderView<ExtraData> = components
        .messageListHeaderView.init()
        .withoutAutoresizingMaskConstraints
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

### `channelAvatarView`

View for displaying the channel image in the navigation bar.

``` swift
open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `typingIndicatorView`

View which displays information about current users who are typing.

``` swift
open private(set) lazy var typingIndicatorView: _TypingIndicatorView<ExtraData> = components
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `scrollToLatestMessageButton`

A button to scroll the collection view to the bottom.

``` swift
open private(set) lazy var scrollToLatestMessageButton: _ScrollToLatestMessageButton<ExtraData> = components
        .scrollToLatestMessageButton
        .init()
        .withoutAutoresizingMaskConstraints
```

Visible when there is unread message and the collection view is not at the bottom already.

### `router`

A router object that handles navigation to other view controllers.

``` swift
open lazy var router 
```

### `typingIndicatorViewHeight`

The height of the typing indicator view

``` swift
open private(set) var typingIndicatorViewHeight: CGFloat = 22
```

### `isScrollToBottomButtonVisible`

``` swift
open var isScrollToBottomButtonVisible: Bool 
```

## Methods

### `traitCollectionDidChange(_:)`

``` swift
override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) 
```

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

### `cellLayoutOptionsForMessage(at:)`

Returns layout options for the message on given `indexPath`.

``` swift
open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions 
```

Layout options are used to determine the layout of the message.
By default there is one message with all possible layout and layout options
determines which parts of the message are visible for the given message.

### `cellContentClassForMessage(at:)`

Returns the content view class for the message at given `indexPath`

``` swift
open func cellContentClassForMessage(at indexPath: IndexPath) -> _ChatMessageContentView<ExtraData>.Type 
```

### `attachmentViewInjectorClassForMessage(at:)`

``` swift
open func attachmentViewInjectorClassForMessage(at indexPath: IndexPath) -> _AttachmentViewInjector<ExtraData>.Type? 
```

### `tableView(_:willDisplay:forRowAt:)`

``` swift
open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) 
```

### `scrollOverlay(_:textForItemAt:)`

``` swift
open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? 
```

### `scrollViewDidScroll(_:)`

``` swift
open func scrollViewDidScroll(_ scrollView: UIScrollView) 
```

### `scrollToMostRecentMessage(animated:)`

Scrolls to most recent message

``` swift
open func scrollToMostRecentMessage(animated: Bool = true) 
```

### `updateScrollToLatestMessageButton()`

Update the `scrollToLatestMessageButton` based on unread messages.

``` swift
open func updateScrollToLatestMessageButton() 
```

### `setScrollToLatestMessageButton(visible:animated:)`

Set the visibility of `scrollToLatestMessageButton`.

``` swift
open func setScrollToLatestMessageButton(visible: Bool, animated: Bool = true) 
```

### `scrollToLatestMessage()`

Action for `scrollToLatestMessageButton` that scroll to most recent message.

``` swift
@objc open func scrollToLatestMessage() 
```

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

### `messageForIndexPath(_:)`

``` swift
open func messageForIndexPath(_ indexPath: IndexPath) -> _ChatMessage<ExtraData> 
```

### `didSelectMessageCell(at:)`

``` swift
open func didSelectMessageCell(at indexPath: IndexPath) 
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

### `didTapOnAttachmentAction(_:at:)`

Executes the provided action on the message

``` swift
open func didTapOnAttachmentAction(
        _ action: AttachmentAction,
        at indexPath: IndexPath
    ) 
```

### `showThread(messageId:)`

Opens thread detail for given `message`

``` swift
open func showThread(messageId: MessageId) 
```

### `composerDidCreateNewMessage()`

``` swift
open func composerDidCreateNewMessage() 
```

### `channelController(_:didUpdateMessages:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
```

### `channelController(_:didUpdateChannel:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) 
```

### `channelController(_:didChangeTypingUsers:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingUsers typingUsers: Set<_ChatUser<ExtraData.User>>
    ) 
```

### `showTypingIndicator(typingUsers:)`

Shows typing Indicator

``` swift
open func showTypingIndicator(typingUsers: [_ChatUser<ExtraData.User>]) 
```

#### Parameters

  - typingUsers: typing users gotten from `channelController`

### `hideTypingIndicator()`

Hides typing Indicator

``` swift
open func hideTypingIndicator() 
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
open func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>) 
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

### `gestureRecognizer(_:shouldReceive:)`

``` swift
open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool 
```
