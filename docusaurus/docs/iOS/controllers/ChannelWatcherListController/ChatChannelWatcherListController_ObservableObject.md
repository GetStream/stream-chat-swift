
A wrapper object for `_ChatChannelWatcherListController` type which makes it possible to use the controller
comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_ChatChannelWatcherListControllerDelegate`](ChatChannelWatcherListControllerDelegate)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatChannelWatcherListController
```

### `watchers`

The channel members.

``` swift
@Published public private(set) var watchers: LazyCachedMapCollection<_ChatUser<ExtraData.User>> = []
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `channelWatcherListController(_:didChangeWatchers:)`

``` swift
public func channelWatcherListController(
        _ controller: _ChatChannelWatcherListController<ExtraData>,
        didChangeWatchers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
