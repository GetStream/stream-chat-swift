---
title: ChatConnectionController
---

`ChatConnectionController` is a controller class which allows to explicitly
connect/disconnect the `ChatClient` and observe connection events.

``` swift
public class _ChatConnectionController<ExtraData: ExtraDataTypes>: Controller, DelegateCallable, DataStoreProvider 
```

Learn more about `ChatConnectionController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#connection).

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`Controller`](../../controller), [`DelegateCallable`](../../delegate-callable), [`DataStoreProvider`](../../../database/data-store-provider)

## Properties

### `connectionStatusPublisher`

A publisher emitting a new value every time the connection status changes.

``` swift
public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `callbackQueue`

``` swift
public var callbackQueue: DispatchQueue = .main
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `connectionStatus`

The current connection status of the client.

``` swift
public var connectionStatus: ConnectionStatus 
```

To observe changes of the connection status, set your class as a delegate of this controller or use the provided
`Combine` publishers.

## Methods

### `connect(completion:)`

Connects the chat client the controller represents to the chat servers.

``` swift
func connect(completion: ((Error?) -> Void)? = nil) 
```

When the connection is established, `ChatClient` starts receiving chat updates.

#### Parameters

  - completion: Called when the connection is established. If the connection fails, the completion is called with an error.

### `disconnect()`

Disconnects the chat client the controller represents from the chat servers.
No further updates from the servers are received.

``` swift
func disconnect() 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
func setDelegate<Delegate: _ChatConnectionControllerDelegate>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.
