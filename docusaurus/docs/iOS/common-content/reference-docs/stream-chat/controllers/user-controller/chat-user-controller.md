---
title: ChatUserController
---

`_ChatUserController` is a controller class which allows mutating and observing changes of a specific chat user.

``` swift
public class ChatUserController: DataController, DelegateCallable, DataStoreProvider 
```

`_ChatUserController` objects are lightweight, and they can be used for both, continuous data change observations,
and for quick user actions (like mute/unmute).

## Inheritance

[`DataController`](../../data-controller), [`DelegateCallable`](../../delegate-callable), [`DataStoreProvider`](../../../database/data-store-provider)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `userChangePublisher`

A publisher emitting a new value every time the user changes.

``` swift
public var userChangePublisher: AnyPublisher<EntityChange<ChatUser>, Never> 
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

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `user`

The user the controller represents.

``` swift
public var user: ChatUser? 
```

To observe changes of the user, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `delegate`

Set the delegate of `ChatUserController` to observe the changes in the system.

``` swift
var delegate: ChatUserControllerDelegate? 
```

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatUserControllerDelegate>(_ delegate: Delegate) 
```

#### Parameters

  - `delegate`: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `mute(completion:)`

Mutes the user this controller manages.

``` swift
func mute(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - `completion`: The completion. Will be called on a **`callbackQueue`** when the network request is finished. If request fails, the completion will be called with an error.

### `unmute(completion:)`

Un-mutes the user this controller manages.

``` swift
func unmute(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - `completion`: The completion. Will be called on a **`callbackQueue`** when the network request is finished.

### `flag(completion:)`

Flags the user this controller manages.

``` swift
func flag(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - `completion`: The completion. Will be called on a **`callbackQueue`** when the network request is finished. If request fails, the completion will be called with an error.

### `unflag(completion:)`

Un-flags the user this controller manages.

``` swift
func unflag(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - `completion`: The completion. Will be called on a **`callbackQueue`** when the network request is finished.
