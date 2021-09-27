---
title: ChatChannelWatcherListController
---

`_ChatChannelWatcherListController` is a controller class which allows observing
a list of chat watchers based on the provided query.

``` swift
public class ChatChannelWatcherListController: DataController, DelegateCallable, DataStoreProvider 
```

## Inheritance

[`DataController`](../../data-controller), [`DelegateCallable`](../../delegate-callable), [`DataStoreProvider`](../../../database/data-store-provider)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `watchersChangesPublisher`

A publisher emitting a new value every time the channel members change.

``` swift
public var watchersChangesPublisher: AnyPublisher<[ListChange<ChatUser>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying sorting and filtering for the list of channel watchers.

``` swift
@Atomic public private(set) var query: ChannelWatcherListQuery
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `watchers`

The channel watchers matching the query.
To observe the watcher list changes, set your class as a delegate of this controller or use the provided
`Combine` publishers.

``` swift
public var watchers: LazyCachedMapCollection<ChatUser> 
```

### `delegate`

Set the delegate of `ChatChannelWatcherListController` to observe the changes in the system.

``` swift
public var delegate: ChatChannelWatcherListControllerDelegate? 
```

## Methods

### `synchronize(_:)`

Synchronizes the channel's watchers with the backend.

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatChannelWatcherListControllerDelegate>(_ delegate: Delegate) 
```

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `loadNextWatchers(limit:completion:)`

Load next set of watchers from backend.

``` swift
func loadNextWatchers(limit: Int = .channelWatchersPageSize, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - limit: Limit for page size. Offset is defined automatically by the controller.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.
