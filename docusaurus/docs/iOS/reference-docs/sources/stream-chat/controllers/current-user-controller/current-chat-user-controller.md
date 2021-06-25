---
title: CurrentChatUserController
---

`CurrentChatUserController` is a controller class which allows observing and mutating the currently logged-in
user of `ChatClient`.

``` swift
public class _CurrentChatUserController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider 
```

Learn more about `CurrentChatUserController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#user).

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`DataController`](../../data-controller), [`DelegateCallable`](../../delegate-callable), [`DataStoreProvider`](../../../database/data-store-provider)

## Properties

### `currentUserChangePublisher`

A publisher emitting a new value every time the current user changes.

``` swift
public var currentUserChangePublisher: AnyPublisher<EntityChange<_CurrentChatUser<ExtraData>>, Never> 
```

### `unreadCountPublisher`

A publisher emitting a new value every time the unread count changes..

``` swift
public var unreadCountPublisher: AnyPublisher<UnreadCount, Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `currentUser`

The currently logged-in user. `nil` if the connection hasn't been fully established yet, or the connection
wasn't successful.

``` swift
public var currentUser: _CurrentChatUser<ExtraData>? 
```

### `unreadCount`

The unread messages and channels count for the current user.

``` swift
public var unreadCount: UnreadCount 
```

Returns `noUnread` if `currentUser` doesn't exist yet.

## Methods

### `synchronize(_:)`

Synchronize local data with remote. Waits for the client to connect but doesn’t initiate the connection itself.
This is to make sure the fetched local data is up-to-date, since the current user data is updated through WebSocket events.

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: Called when the controller has finished fetching the local data and the client connection is established.

### `reloadUserIfNeeded(completion:)`

Fetches the token from `tokenProvider` and prepares the current `ChatClient` variables
for the new user.

``` swift
func reloadUserIfNeeded(completion: ((Error?) -> Void)? = nil) 
```

If the a token obtained from `tokenProvider` is for another user the
database will be flushed.

If `config.shouldConnectAutomatically` is set to `true` it also
tries to establish a web-socket connection.

If `config.shouldConnectAutomatically` is set to `false` the
establishing a web-socket connection has to be done manually via `connect/disconnect`
methods in `ChatConnectionController`.

#### Parameters

  - completion: The completion to be called when the operation is completed.

### `updateUserData(name:imageURL:userExtraData:completion:)`

Updates the current user data.

``` swift
func updateUserData(
        name: String? = nil,
        imageURL: URL? = nil,
        userExtraData: ExtraData.User? = nil,
        completion: ((Error?) -> Void)? = nil
    ) 
```

By default all data is `nil`, and it won't be updated unless a value is provided.

#### Parameters

  - name: Optionally provide a new name to be updated.
  - imageURL: Optionally provide a new image to be updated.
  - userExtraData: Optionally provide new user extra data to be updated.
  - completion: Called when user is successfuly updated, or with error.

### `synchronizeDevices(completion:)`

Fetches the most updated devices and syncs with the local database.

``` swift
func synchronizeDevices(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: Called when the devices are synced successfully, or with error.

### `addDevice(token:completion:)`

Registers a device to the current user.
`setUser` must be called before calling this.

``` swift
func addDevice(token: Data, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - token: Device token, obtained via `didRegisterForRemoteNotificationsWithDeviceToken` function in `AppDelegate`.
  - completion: Called when device is successfully registered, or with error.

### `removeDevice(id:completion:)`

Removes a registered device from the current user.
`setUser` must be called before calling this.

``` swift
func removeDevice(id: String, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - id: Device id to be removed. You can obtain registered devices via `currentUser.devices`. If `currentUser.devices` is not up-to-date, please make an `synchronize` call.
  - completion: Called when device is successfully deregistered, or with error.

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
func setDelegate<Delegate: _CurrentChatUserControllerDelegate>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.
