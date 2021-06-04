
Describes the possible states of the client connection to the servers.

``` swift
public enum ConnectionStatus: Equatable 
```

## Inheritance

`Equatable`

## Enumeration Cases

### `initialized`

The client is initialized but not connected to the remote server yet.

``` swift
case initialized
```

### `disconnected`

The client is disconnected. This is an initial state. Optionally contains an error, if the connection was disconnected
due to an error.

``` swift
case disconnected(error: ClientError? = nil)
```

### `connecting`

The client is in the process of connecting to the remote servers.

``` swift
case connecting
```

### `connected`

The client is connected to the remote server.

``` swift
case connected
```

### `disconnecting`

The web socket is disconnecting.

``` swift
case disconnecting
```
