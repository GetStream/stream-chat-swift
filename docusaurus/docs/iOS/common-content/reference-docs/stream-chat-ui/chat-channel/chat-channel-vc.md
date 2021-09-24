---
title: ChatChannelVC
---

Controller responsible for displaying the channel messages.

``` swift
@available(iOSApplicationExtension, unavailable)
open class ChatChannelVC:
    _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatChannelControllerDelegate 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), `ChatChannelControllerDelegate`, [`ChatMessageListVCDataSource`](../../chat-message-list/chat-message-list-vc-data-source), [`ChatMessageListVCDelegate`](../../chat-message-list/chat-message-list-vc-delegate), [`SwiftUIRepresentable`](../../common-views/swift-ui-representable), [`ThemeProvider`](../../utils/theme-provider)

## Properties

### `content`

``` swift
public var content: ChatChannelController 
```

### `channelController`

Controller for observing data changes within the channel.

``` swift
open var channelController: ChatChannelController!
```

### `userSuggestionSearchController`

User search controller for suggestion users when typing in the composer.

``` swift
open lazy var userSuggestionSearchController: ChatUserSearchController 
```

### `channelAvatarSize`

The size of the channel avatar.

``` swift
open var channelAvatarSize: CGSize 
```

### `client`

``` swift
public var client: ChatClient 
```

### `keyboardHandler`

Component responsible for setting the correct offset when keyboard frame is changed.

``` swift
open lazy var keyboardHandler: KeyboardHandler 
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

Header View

``` swift
open private(set) lazy var headerView: ChatChannelHeaderView = components
        .channelHeaderView.init()
        .withoutAutoresizingMaskConstraints
```

### `channelAvatarView`

View for displaying the channel image in the navigation bar.

``` swift
open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints
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
open func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) 
```

### `channelController(_:didUpdateChannel:)`

``` swift
open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) 
```

### `channelController(_:didChangeTypingUsers:)`

``` swift
open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) 
```
