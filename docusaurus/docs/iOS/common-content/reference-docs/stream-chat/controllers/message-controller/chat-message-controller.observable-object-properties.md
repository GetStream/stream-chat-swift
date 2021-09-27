
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatMessageController
```

### `message`

The message that current controller observes.

``` swift
@Published public private(set) var message: ChatMessage?
```

### `replies`

The replies to the message controller observes.

``` swift
@Published public private(set) var replies: LazyCachedMapCollection<ChatMessage> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `messageController(_:didChangeMessage:)`

``` swift
public func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) 
```

### `messageController(_:didChangeReplies:)`

``` swift
public func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
