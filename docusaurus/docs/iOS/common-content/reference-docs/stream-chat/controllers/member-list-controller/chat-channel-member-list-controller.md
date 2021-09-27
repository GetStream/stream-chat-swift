---
title: ChatChannelMemberListController
---

`ChatChannelMemberListController` is a controller class which allows observing
a list of chat users based on the provided query.

``` swift
public class ChatChannelMemberListController: DataController, DelegateCallable, DataStoreProvider 
```

## Inheritance

[`DataController`](../../data-controller), [`DelegateCallable`](../../delegate-callable), [`DataStoreProvider`](../../../database/data-store-provider)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `membersChangesPublisher`

A publisher emitting a new value every time the channel members change.

``` swift
public var membersChangesPublisher: AnyPublisher<[ListChange<ChatChannelMember>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying sorting and filtering for the list of channel members.

``` swift
@Atomic public private(set) var query: ChannelMemberListQuery
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `members`

The channel members matching the query.
To observe the member list changes, set your class as a delegate of this controller or use the provided
`Combine` publishers.

``` swift
public var members: LazyCachedMapCollection<ChatChannelMember> 
```

### `delegate`

Set the delegate of `ChatChannelMemberListController` to observe the changes in the system.

``` swift
public var delegate: ChatChannelMemberListControllerDelegate? 
```

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatChannelMemberListControllerDelegate>(_ delegate: Delegate) 
```

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
