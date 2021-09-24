---
title: ChatThreadVC
---

Controller responsible for displaying message thread.

``` swift
@available(iOSApplicationExtension, unavailable)
open class ChatThreadVC:
    _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatMessageControllerDelegate 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), `ChatMessageControllerDelegate`, [`ChatMessageListVCDataSource`](../../chat-message-list/chat-message-list-vc-data-source), [`ChatMessageListVCDelegate`](../../chat-message-list/chat-message-list-vc-delegate), [`SwiftUIRepresentable`](../../common-views/swift-ui-representable), [`ThemeProvider`](../../utils/theme-provider)

## Properties

### `content`

``` swift
public var content: (
        channelController: ChatChannelController,
        messageController: ChatMessageController
    ) 
```

### `channelController`

Controller for observing data changes within the channel

``` swift
open var channelController: ChatChannelController!
```

### `messageController`

Controller for observing data changes within the parent thread message.

``` swift
open var messageController: ChatMessageController!
```

### `client`

``` swift
public var client: ChatClient 
```

### `keyboardHandler`

Component responsible for setting the correct offset when keyboard frame is changed

``` swift
open lazy var keyboardHandler: KeyboardHandler 
```

### `userSuggestionSearchController`

User search controller passed directly to the composer

``` swift
open lazy var userSuggestionSearchController: ChatUserSearchController 
```

### `messageListVC`

The message list component responsible to render the messages.

``` swift
open lazy var messageListVC: ChatMessageListVC 
```

### `messageComposerVC`

Controller that handles the composer view

``` swift
open private(set) lazy var messageComposerVC 
```

### `headerView`

The header view of the thread that by default is the titleView of the navigation bar.

``` swift
open lazy var headerView: ChatThreadHeaderView = components
        .threadHeaderView.init()
        .withoutAutoresizingMaskConstraints
```

### `replies`

``` swift
open var replies: [ChatMessage] 
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

### `viewDidAppear(_:)`

``` swift
override open func viewDidAppear(_ animated: Bool) 
```

### `viewDidDisappear(_:)`

``` swift
override open func viewDidDisappear(_ animated: Bool) 
```

### `channel(for:)`

``` swift
open func channel(for vc: ChatMessageListVC) -> ChatChannel? 
```

### `numberOfMessages(in:)`

``` swift
open func numberOfMessages(in vc: ChatMessageListVC) -> Int 
```

### `chatMessageListVC(_:messageAt:)`

``` swift
open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? 
```

### `chatMessageListVC(_:messageLayoutOptionsAt:)`

``` swift
open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions 
```

### `chatMessageListVC(_:willDisplayMessageAt:)`

``` swift
open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) 
```

### `chatMessageListVC(_:didTapOnAction:for:)`

``` swift
open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) 
```

### `chatMessageListVC(_:scrollViewDidScroll:)`

``` swift
open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    ) 
```

### `messageController(_:didChangeMessage:)`

``` swift
open func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) 
```

### `messageController(_:didChangeReplies:)`

``` swift
open func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) 
```
