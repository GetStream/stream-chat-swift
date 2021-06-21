---
id: chatthreadvc 
title: ChatThreadVC
--- 

Controller responsible for displaying message thread.

``` swift
open class _ChatThreadVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    ThemeProvider,
    ComposerVCDelegate,
    _ChatChannelControllerDelegate,
    _ChatMessageControllerDelegate,
    _ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource 
```

## Inheritance

[`_ViewController`](../CommonViews/_ViewController), [`ChatMessageContentViewDelegate`](ChatMessage/ChatMessageContentViewDelegate), [`ComposerVCDelegate`](../Composer/ComposerVCDelegate), [`ThemeProvider`](../Utils/ThemeProvider), `UICollectionViewDataSource`, `UICollectionViewDelegate`, `_ChatChannelControllerDelegate`, [`_ChatMessageActionsVCDelegate`](../MessageActionsPopup/ChatMessageActionsVCDelegate), `_ChatMessageControllerDelegate`

## Properties

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

### `messageListLayout`

Layout used by the collection view.

``` swift
open lazy var messageListLayout: ChatMessageListCollectionViewLayout 
```

### `collectionView`

View used to display the messages

``` swift
open private(set) lazy var collectionView: ChatMessageListCollectionView<ExtraData> 
```

### `messageComposerVC`

Controller that handles the composer view

``` swift
open private(set) lazy var messageComposerVC 
```

### `titleView`

View displaying status of the channel.

``` swift
open lazy var titleView: TitleContainerView = components
        .navigationTitleView.init()
        .withoutAutoresizingMaskConstraints
```

The status differs based on the fact if the channel is direct or not.

### `router`

Handles navigation actions from messages

``` swift
open lazy var router 
```

### `threadRootMessageLayoutOptions`

Returns the layout options for thread root message header.

``` swift
open var threadRootMessageLayoutOptions: ChatMessageLayoutOptions 
```

### `threadRootMessageAttachmentViewInjectorClass`

Returns the attachment view injector class for thread root message header.

``` swift
open var threadRootMessageAttachmentViewInjectorClass: _AttachmentViewInjector<ExtraData>.Type? 
```

### `threadRootMessageContentClass`

Returns the content view class for thread root message header.

``` swift
open var threadRootMessageContentClass: _ChatMessageContentView<ExtraData>.Type 
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

### `collectionView(_:numberOfItemsInSection:)`

``` swift
open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int 
```

### `collectionView(_:cellForItemAt:)`

``` swift
open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell 
```

### `collectionView(_:willDisplay:forItemAt:)`

``` swift
open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) 
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

### `addThreadRootMessageHeader()`

Adds thread parent message on top of collection view.

``` swift
open func addThreadRootMessageHeader() 
```

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
open func updateMessages(with changes: [ListChange<_ChatMessage<ExtraData>>], completion: ((Bool) -> Void)? = nil) 
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

### `messageForIndexPath(_:)`

``` swift
open func messageForIndexPath(_ indexPath: IndexPath) -> _ChatMessage<ExtraData> 
```
