
### `channelController`

Controller for observing data changes within the channel.

``` swift
open var channelController: ChatChannelController?
```

### `currentUserId`

The user id of the current logged in user.

``` swift
open var currentUserId: UserId? 
```

### `titleContainerView`

A view that displays a title label and subtitle in a container stack view.

``` swift
open private(set) lazy var titleContainerView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints
```

### `titleText`

The title text used to render the title label. By default it is "Thread Reply" label.

``` swift
open var titleText: String? 
```

### `subtitleText`

The subtitle text used in the subtitle label. By default it is the channel name.

``` swift
open var subtitleText: String? 
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

### `updateContent()`

``` swift
override open func updateContent() 
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

### `channelController(_:didReceiveMemberEvent:)`

``` swift
open func channelController(
        _ channelController: ChatChannelController,
        didReceiveMemberEvent: MemberEvent
    ) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) 
