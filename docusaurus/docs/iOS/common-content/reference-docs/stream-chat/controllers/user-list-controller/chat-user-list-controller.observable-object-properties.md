
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatUserListController
```

### `users`

The users matching the query.

``` swift
@Published public private(set) var users: LazyCachedMapCollection<_ChatUser<ExtraData.User>> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `controller(_:didChangeUsers:)`

``` swift
public func controller(
        _ controller: _ChatUserListController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
