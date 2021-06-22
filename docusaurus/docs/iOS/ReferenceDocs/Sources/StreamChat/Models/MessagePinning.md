---
id: messagepinning 
title: MessagePinning
slug: /ReferenceDocs/Sources/StreamChat/Models/messagepinning
---

Describes the pinning expiration

``` swift
public struct MessagePinning: Equatable 
```

## Inheritance

`Equatable`

## Properties

### `expirationDate`

The expiration date of the pinning. Infinite expiration in case it is `nil`.

``` swift
public let expirationDate: Date?
```

### `noExpiration`

Pins a message with infinite expiration.

``` swift
public static let noExpiration 
```

## Methods

### `expirationDate(_:)`

Pins a message.

``` swift
public static func expirationDate(_ date: Date) -> Self 
```

#### Parameters

  - date: The date when the message will be unpinned.

### `expirationTime(_:)`

Pins a message.

``` swift
public static func expirationTime(_ time: TimeInterval) -> Self 
```

#### Parameters

  - time: The amount of seconds the message will be pinned.
