---
title: ChatChannelListController.ObservableObject
---

A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_ChatChannelListControllerDelegate`](../chat-channel-list-controller-delegate)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatChannelListController
```

### `channels`

The channels matching the query.

``` swift
@Published public private(set) var channels: LazyCachedMapCollection<_ChatChannel<ExtraData>> = []
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
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
