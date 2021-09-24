---
title: ChatConnectionControllerDelegate
---

`ChatConnectionController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatConnectionControllerDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `connectionController(_:didUpdateConnectionStatus:)`

``` swift
func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) 
```

## Requirements

### connectionController(\_:​didUpdateConnectionStatus:​)

The controller observed a change in connection status.

``` swift
func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus)
```
