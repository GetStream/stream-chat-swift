
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatChannelMemberListController
```

### `members`

The channel members.

``` swift
@Published public private(set) var members: LazyCachedMapCollection<_ChatChannelMember<ExtraData.User>> = []
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `memberListController(_:didChangeMembers:)`

``` swift
public func memberListController(
        _ controller: _ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<_ChatChannelMember<ExtraData.User>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
