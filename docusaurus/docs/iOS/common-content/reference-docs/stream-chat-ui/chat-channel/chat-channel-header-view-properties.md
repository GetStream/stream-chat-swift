
### `channelController`

Controller for observing data changes within the channel.

``` swift
open var channelController: ChatChannelController? 
```

### `lastSeenDateFormatter`

Returns the date formater function used to represent when the user was last seen online

``` swift
open var lastSeenDateFormatter: (Date) -> String? 
```

### `currentUserId`

The user id of the current logged in user.

``` swift
open var currentUserId: UserId? 
```

### `timer`

Timer used to update the online status of member in the channel.

``` swift
open var timer: Timer? 
```

### `statusUpdateInterval`

The amount of time it updates the online status of the members.
By default it is 60 seconds.

``` swift
open var statusUpdateInterval: TimeInterval 
```

### `titleContainerView`

A view that displays a title label and subtitle in a container stack view.

``` swift
open private(set) lazy var titleContainerView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints
```

### `titleText`

The title text used to render the title label. By default it is the channel name.

``` swift
open var titleText: String? 
```

### `subtitleText`

The subtitle text used in the subtitle label. By default it shows member online status.

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

### `makeTimer()`

Create the timer to repeatedly update the online status of the members.

``` swift
open func makeTimer() 
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
