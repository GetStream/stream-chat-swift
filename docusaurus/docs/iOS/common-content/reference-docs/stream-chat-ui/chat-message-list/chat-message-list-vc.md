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
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    LinkPreviewViewDelegate,
    FileActionContentViewDelegate,
    ChatMessageListViewDataSource 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), [`FileActionContentViewDelegate`](../attachments/file-action-content-view-delegate), [`GalleryContentViewDelegate`](../attachments/gallery-content-view-delegate), [`GiphyActionContentViewDelegate`](../attachments/giphy-action-content-view-delegate), [`LinkPreviewViewDelegate`](../attachments/link-preview-view-delegate), [`ChatMessageContentViewDelegate`](../chat-message/chat-message-content-view-delegate), [`ChatMessageListViewDataSource`](../chat-message-list-view-data-source), [`SwiftUIRepresentable`](../../common-views/swift-ui-representable), [`ComposerVCDelegate`](../../composer/composer-vc-delegate), `UITableViewDataSource`, `UITableViewDelegate`, `_ChatChannelControllerDelegate`, [`_ChatMessageActionsVCDelegate`](../../message-actions-popup/chat-message-actions-vc-delegate), [`ThemeProvider`](../../utils/theme-provider)

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

### `messageComposerVC`

Controller that handles the composer view

``` swift
open private(set) lazy var messageComposerVC 
```

### `titleView`

View displaying status of the channel.

``` swift
open private(set) lazy var titleView: TitleContainerView = components.navigationTitleView.init()
        .withoutAutoresizingMaskConstraints
```

The status differs based on the fact if the channel is direct or not.

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

### `overlayDateFormatter`

Formatter that is used to format date for scrolling overlay that should display day when message below were sent

``` swift
open var overlayDateFormatter: DateFormatter 
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

### `messageListView(_:scrollOverlayTextForItemAt:)`

``` swift
open func messageListView(
        _ tableView: UITableView,
        scrollOverlayTextForItemAt indexPath: IndexPath
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

### `updateNavigationBarContent()`

Updates the status data in `titleView`.

``` swift
open func updateNavigationBarContent() 
```

If the channel is direct between two people this method is called repeatedly every minute
to update the online status of the members.
For group chat is called every-time the channel changes.

### `handleLongPress(_:)`

Handles long press action on collection view.

``` swift
@objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) 
```

Default implementation will convert the gesture location to collection view's `indexPath`
and then call selection action on the selected cell.

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

### `restartUploading(for:)`

Restarts upload of given `attachment` in case of failure

``` swift
open func restartUploading(for attachmentId: AttachmentId) 
```

### `didTapOnImageAttachment(_:previews:at:)`

``` swift
open func didTapOnImageAttachment(
        _ attachment: ChatMessageImageAttachment,
        previews: [ImagePreviewable],
        at indexPath: IndexPath?
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

### `channelController(_:didChangeTypingMembers:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) 
```

### `showTypingIndicator(typingMembers:)`

Shows typing Indicator

``` swift
open func showTypingIndicator(typingMembers: [_ChatChannelMember<ExtraData.User>]) 
```

#### Parameters

  - typingMembers: typing members gotten from `channelController`

### `hideTypingIndicator()`

Hides typing Indicator

``` swift
open func hideTypingIndicator() 
```

#### Parameters

  - typingMembers: typing members gotten from `channelController`

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
