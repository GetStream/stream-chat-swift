---
title: ChatConnectionController.ObservableObject
---

A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`ChatConnectionControllerDelegate`](../chat-connection-controller-delegate), `SwiftUI.ObservableObject`

## Properties

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
```
