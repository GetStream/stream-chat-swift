---
title: ChatChannelMemberController
---

`ChatChannelMemberController` is a controller class which allows mutating and observing changes of a specific chat member.

``` swift
public class ChatChannelMemberController: DataController, DelegateCallable, DataStoreProvider 
```

## Inheritance

[`DataController`](../../data-controller), [`DelegateCallable`](../../delegate-callable), [`DataStoreProvider`](../../../database/data-store-provider)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `memberChangePublisher`

A publisher emitting a new value every time the member changes.

``` swift
public var memberChangePublisher: AnyPublisher<EntityChange<ChatChannelMember>, Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `userId`

The identifier of the user this controller observes.

``` swift
public let userId: UserId
```

### `cid`

The identifier of the channel the user is member of.

``` swift
public let cid: ChannelId
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `member`

The user the controller represents.

``` swift
public var member: ChatChannelMember? 
```

To observe changes of the chat member, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `delegate`

Set the delegate of `ChatMemberController` to observe the changes in the system.

``` swift
var delegate: ChatChannelMemberControllerDelegate? 
```

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatChannelMemberControllerDelegate>(_ delegate: Delegate) 
```

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `ban(for:reason:completion:)`

Bans the channel member for a specific \# of minutes.

``` swift
func ban(
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - timeoutInMinutes: The \# of minutes the user should be banned for.
  - reason: The ban reason.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `unban(completion:)`

Unbans the channel member.

``` swift
func unban(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.
