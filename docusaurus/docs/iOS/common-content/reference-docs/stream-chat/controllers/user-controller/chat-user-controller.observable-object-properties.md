
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatUserController
```

### `user`

The user matching the `userId`.

``` swift
@Published public private(set) var user: ChatUser?
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `userController(_:didUpdateUser:)`

``` swift
public func userController(
        _ controller: ChatUserController,
        didUpdateUser change: EntityChange<ChatUser>
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
