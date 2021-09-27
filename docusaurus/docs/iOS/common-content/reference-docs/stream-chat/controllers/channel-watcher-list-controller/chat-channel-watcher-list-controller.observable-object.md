---
title: ChatChannelWatcherListController.ObservableObject
---

A wrapper object for `_ChatChannelWatcherListController` type which makes it possible to use the controller
comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`ChatChannelWatcherListControllerDelegate`](../chat-channel-watcher-list-controller-delegate), `SwiftUI.ObservableObject`

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatChannelWatcherListController
```

### `watchers`

The channel members.

``` swift
@Published public private(set) var watchers: LazyCachedMapCollection<ChatUser> = []
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
        _ controller: ChatChannelWatcherListController,
        didChangeWatchers changes: [ListChange<ChatUser>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
