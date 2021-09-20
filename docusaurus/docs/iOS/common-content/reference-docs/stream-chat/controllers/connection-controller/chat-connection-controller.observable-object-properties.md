
### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatConnectionController
```

### `connectionStatus`

The connection status.

``` swift
@Published public private(set) var connectionStatus: ConnectionStatus
```

## Methods

### `connectionController(_:didUpdateConnectionStatus:)`

``` swift
public func connectionController(
        _ controller: ChatConnectionController,
        didUpdateConnectionStatus status: ConnectionStatus
    ) 
