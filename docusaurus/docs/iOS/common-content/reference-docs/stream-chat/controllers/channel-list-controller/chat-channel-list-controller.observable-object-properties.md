
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatChannelListController
```

### `channels`

The channels matching the query.

``` swift
@Published public private(set) var channels: LazyCachedMapCollection<ChatChannel> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `controller(_:didChangeChannels:)`

``` swift
public func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
