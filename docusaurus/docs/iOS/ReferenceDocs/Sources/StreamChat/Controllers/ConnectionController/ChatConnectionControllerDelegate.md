
`ChatConnectionController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatConnectionControllerDelegate: AnyObject 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatConnectionControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

`AnyObject`

## Default Implementations

### `connectionController(_:didUpdateConnectionStatus:)`

``` swift
func connectionController(
        _ controller: _ChatConnectionController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### connectionController(\_:​didUpdateConnectionStatus:​)

The controller observed a change in connection status.

``` swift
func connectionController(
        _ controller: _ChatConnectionController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    )
```
