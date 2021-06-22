---
id: chatusercontroller 
title: ChatUserController
slug: /ReferenceDocs/Sources/StreamChat/Controllers/UserController/chatusercontroller
---

`_ChatUserController` is a controller class which allows mutating and observing changes of a specific chat user.

``` swift
public class _ChatUserController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider 
```

`_ChatUserController` objects are lightweight, and they can be used for both, continuous data change observations,
and for quick user actions (like mute/unmute).

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`DataController`](../DataController), [`DelegateCallable`](../DelegateCallable), [`DataStoreProvider`](../../Database/DataStoreProvider)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `userChangePublisher`

A publisher emitting a new value every time the user changes.

``` swift
public var userChangePublisher: AnyPublisher<EntityChange<_ChatUser<ExtraData.User>>, Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `userId`

The identifier of tge user this controller observes.

``` swift
public let userId: UserId
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `user`

The user the controller represents.

``` swift
public var user: _ChatUser<ExtraData.User>? 
```

To observe changes of the user, set your class as a delegate of this controller or use the provided
`Combine` publishers.

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: _ChatUserControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `mute(completion:)`

Mutes the user this controller manages.

``` swift
func mute(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `unmute(completion:)`

Unmutes the user this controller manages.

``` swift
func unmute(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.

### `flag(completion:)`

Flags the user this controller manages.

``` swift
func flag(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `unflag(completion:)`

Unflags the user this controller manages.

``` swift
func unflag(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
