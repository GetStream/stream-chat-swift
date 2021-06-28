---
title: ChatChannelListController
---

`_ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.

``` swift
public class _ChatChannelListController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider 
```

Learn more about `_ChatChannelListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#channel-list).

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`DataController`](../data-controller.md), [`DelegateCallable`](../delegate-callable.md), [`DataStoreProvider`](../../database/data-store-provider.md)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `channelsChangesPublisher`

A publisher emitting a new value every time the list of the channels matching the query changes.

``` swift
public var channelsChangesPublisher: AnyPublisher<[ListChange<_ChatChannel<ExtraData>>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying and filtering the list of channels.

``` swift
public let query: _ChannelListQuery<ExtraData.Channel>
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `channels`

The channels matching the query of this controller.

``` swift
public var channels: LazyCachedMapCollection<_ChatChannel<ExtraData>> 
```

To observe changes of the channels, set your class as a delegate of this controller or use the provided
`Combine` publishers.

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: _ChatChannelListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `loadNextChannels(limit:completion:)`

Loads next channels from backend.

``` swift
public func loadNextChannels(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - limit: Limit for page size.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `markAllRead(completion:)`

Marks all channels for a user as read.

``` swift
public func markAllRead(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
