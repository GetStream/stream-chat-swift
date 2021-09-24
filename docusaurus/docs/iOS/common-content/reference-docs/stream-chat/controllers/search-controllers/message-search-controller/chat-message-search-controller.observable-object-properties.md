
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatMessageSearchController
```

### `messages`

The current result of messages.

``` swift
@Published public private(set) var messages: LazyCachedMapCollection<ChatMessage> = []
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `controller(_:didChangeMessages:)`

``` swift
public func controller(_ controller: ChatMessageSearchController, didChangeMessages changes: [ListChange<ChatMessage>]) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
