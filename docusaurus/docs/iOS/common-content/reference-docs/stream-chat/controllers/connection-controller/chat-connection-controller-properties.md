
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
public let client: ChatClient
```

### `connectionStatus`

The current connection status of the client.

``` swift
public var connectionStatus: ConnectionStatus 
```

To observe changes of the connection status, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `delegate`

Set the delegate of `ChatConnectionController` to observe the changes in the system.

``` swift
var delegate: ChatConnectionControllerDelegate? 
```

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
func setDelegate<Delegate: ChatConnectionControllerDelegate>(_ delegate: Delegate?) 
```

#### Parameters

