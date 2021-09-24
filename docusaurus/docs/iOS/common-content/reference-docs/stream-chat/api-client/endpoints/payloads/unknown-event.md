---
title: UnknownEvent
---

An event type SDK fallbacks to if incoming event was failed to be
decoded as a system event.

``` swift
public struct UnknownEvent: Event, Hashable 
```

## Inheritance

`Decodable`, [`Event`](../../../../web-socket-client/events/event), `Hashable`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `type`

An event type.

``` swift
public let type: EventType
```

### `cid`

A channel identifier the event is observed in.

``` swift
public let cid: ChannelId
```

### `userId`

A user identifier the event is sent by.

``` swift
public let userId: UserId
```

### `createdAt`

An event creation date.

``` swift
public let createdAt: Date
```

## Methods

### `payload(ofType:)`

Decodes a payload of the given type from the event.

``` swift
func payload<T: CustomEventPayload>(ofType: T.Type) -> T? 
```

#### Parameters

  - ofType: The type of payload the custom fields should be treated as.

#### Returns

A payload of the given type if decoding succeeds and if event type matches the one declared in custom payload type. Otherwise `nil` is returned.
