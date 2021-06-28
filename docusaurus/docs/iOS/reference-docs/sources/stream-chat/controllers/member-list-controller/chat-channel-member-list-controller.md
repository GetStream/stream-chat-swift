---
title: ChatChannelMemberListController
---

`_ChatChannelMemberListController` is a controller class which allows observing
a list of chat users based on the provided query.

``` swift
public class _ChatChannelMemberListController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider 
```

Learn more about `_ChatChannelMemberListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).

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

### `membersChangesPublisher`

A publisher emitting a new value every time the channel members change.

``` swift
public var membersChangesPublisher: AnyPublisher<[ListChange<_ChatChannelMember<ExtraData.User>>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying sorting and filtering for the list of channel members.

``` swift
@Atomic public private(set) var query: _ChannelMemberListQuery<ExtraData.User>
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `members`

The channel members matching the query.
To observe the member list changes, set your class as a delegate of this controller or use the provided
`Combine` publishers.

``` swift
public var members: LazyCachedMapCollection<_ChatChannelMember<ExtraData.User>> 
```

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: _ChatChannelMemberListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `loadNextMembers(limit:completion:)`

Loads next members from backend.

``` swift
func loadNextMembers(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - limit: The page size.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.
