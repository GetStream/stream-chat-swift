---
title: ChatMessageListVC
---

Controller that shows list of messages and composer together in the selected channel.

``` swift
@available(iOSApplicationExtension, unavailable)
open class ChatMessageListVC:
    _ViewController,
    ThemeProvider,
    ChatMessageListScrollOverlayDataSource,
    ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    FileActionContentViewDelegate,
    LinkPreviewViewDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UIGestureRecognizerDelegate,
    UIAdaptivePresentationControllerDelegate 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), [`FileActionContentViewDelegate`](../attachments/file-action-content-view-delegate), [`GalleryContentViewDelegate`](../attachments/gallery-content-view-delegate), [`GiphyActionContentViewDelegate`](../attachments/giphy-action-content-view-delegate), [`LinkPreviewViewDelegate`](../attachments/link-preview-view-delegate), [`ChatMessageContentViewDelegate`](../chat-message/chat-message-content-view-delegate), [`ChatMessageListScrollOverlayDataSource`](../chat-message-list-scroll-overlay-data-source), [`ChatMessageActionsVCDelegate`](../../message-actions-popup/chat-message-actions-vc-delegate), [`ThemeProvider`](../../utils/theme-provider), `UIAdaptivePresentationControllerDelegate`, `UIGestureRecognizerDelegate`, `UITableViewDataSource`, `UITableViewDelegate`

## Properties

### `dataSource`

The object that acts as the data source of the message list.

``` swift
public weak var dataSource: ChatMessageListVCDataSource?
```

### `delegate`

The object that acts as the delegate of the message list.

``` swift
public weak var delegate: ChatMessageListVCDelegate?
```

### `client`

The root object representing the Stream Chat.

``` swift
public var client: ChatClient!
```

### `router`

The router object that handles navigation to other view controllers.

``` swift
open lazy var router: ChatMessageListRouter 
```

### `listView`

A View used to display the messages

``` swift
open private(set) lazy var listView: ChatMessageListView 
```

### `dateOverlayView`

A View used to display date of currently displayed messages

``` swift
open private(set) lazy var dateOverlayView: ChatMessageListScrollOverlayView 
```

### `typingIndicatorView`

A View which displays information about current users who are typing.

``` swift
open private(set) lazy var typingIndicatorView: TypingIndicatorView = components
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `typingIndicatorViewHeight`

The height of the typing indicator view

``` swift
open private(set) var typingIndicatorViewHeight: CGFloat = 28
```

### `isTypingEventsEnabled`

A Boolean value indicating whether the typing events are enabled.

``` swift
open var isTypingEventsEnabled: Bool 
```

### `scrollToLatestMessageButton`

A button to scroll the collection view to the bottom.
Visible when there is unread message and the collection view is not at the bottom already.

``` swift
open private(set) lazy var scrollToLatestMessageButton: ScrollToLatestMessageButton = components
        .scrollToLatestMessageButton
        .init()
        .withoutAutoresizingMaskConstraints
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
open func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type 
```

### `attachmentViewInjectorClassForMessage(at:)`

Returns the attachment view injector for the message at given `indexPath`

``` swift
open func attachmentViewInjectorClassForMessage(at indexPath: IndexPath) -> AttachmentViewInjector.Type? 
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

### `scrollToMostRecentMessage(animated:)`

Scrolls to most recent message

``` swift
open func scrollToMostRecentMessage(animated: Bool = true) 
```

### `updateMessages(with:completion:)`

Updates the collection view data with given `changes`.

``` swift
open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) 
```

### `handleTap(_:)`

Handles tap action on the table view.

``` swift
@objc open func handleTap(_ gesture: UITapGestureRecognizer) 
```

Default implementation will dismiss the keyboard if it is open

### `handleLongPress(_:)`

Handles long press action on collection view.

``` swift
@objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) 
```

Default implementation will convert the gesture location to collection view's `indexPath`
and then call selection action on the selected cell.

### `didSelectMessageCell(at:)`

The message cell was select and should show the available message actions.

``` swift
open func didSelectMessageCell(at indexPath: IndexPath) 
```

#### Parameters

  - indexPath: The index path that the message was selected.

### `showThread(messageId:)`

Opens thread detail for given `MessageId`.

``` swift
open func showThread(messageId: MessageId) 
```

### `showTypingIndicator(typingUsers:)`

Shows typing Indicator.

``` swift
open func showTypingIndicator(typingUsers: [ChatUser]) 
```

#### Parameters

  - typingUsers: typing users gotten from `channelController`

### `hideTypingIndicator()`

Hides typing Indicator.

``` swift
open func hideTypingIndicator() 
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

### `scrollViewDidScroll(_:)`

``` swift
open func scrollViewDidScroll(_ scrollView: UIScrollView) 
```

### `scrollOverlay(_:textForItemAt:)`

``` swift
open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? 
```

### `chatMessageActionsVC(_:message:didTapOnActionItem:)`

``` swift
open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) 
```

### `chatMessageActionsVCDidFinish(_:)`

``` swift
open func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC) 
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

### `messageContentViewDidTapOnAvatarView(_:)`

``` swift
open func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) 
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

### `gestureRecognizer(_:shouldReceive:)`

``` swift
open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool 
```

### `presentationControllerShouldDismiss(_:)`

``` swift
public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool 
```
