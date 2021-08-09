
### `channelController`

Controller for observing data changes within the channel.

``` swift
open var channelController: _ChatChannelController<ExtraData>?
```

### `currentUserId`

The user id of the current logged in user.

``` swift
open var currentUserId: UserId? 
```

### `client`

The chat client instance provided by the channel controller.

``` swift
open var client: _ChatClient<ExtraData>? 
```

### `timer`

Timer used to update the online status of member in the chat channel.

``` swift
open var timer: Timer?
```

### `titleContainerView`

A view that displays a title label and subtitle in a container stack view.

``` swift
open private(set) lazy var titleContainerView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints
```

### `titleText`

The title text used to render the title label

``` swift
open var titleText: String? 
```

### `subtitleText`

The subtitle text used to render subtitle label

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

### `channelController(_:didReceiveMemberEvent:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didReceiveMemberEvent: MemberEvent
    ) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
