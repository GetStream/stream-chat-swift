---
title: ConnectionStatusUpdated
---

Emitted when `Client` changes it's connection status. You can listen to this event and indicate the different connection
states in the UI (banners like "Offline", "Reconnecting"", etc.).

``` swift
public struct ConnectionStatusUpdated: Event 
```

## Inheritance

[`Event`](event.md)

## Properties

### `connectionStatus`

The current connection status of `Client`

``` swift
public let connectionStatus: ConnectionStatus
```
