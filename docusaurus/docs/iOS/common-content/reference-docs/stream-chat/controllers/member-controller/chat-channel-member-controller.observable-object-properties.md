
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatChannelMemberController
```

### `member`

The channel member.

``` swift
@Published public private(set) var member: ChatChannelMember?
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `memberController(_:didUpdateMember:)`

``` swift
public func memberController(
        _ controller: ChatChannelMemberController,
        didUpdateMember change: EntityChange<ChatChannelMember>
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
