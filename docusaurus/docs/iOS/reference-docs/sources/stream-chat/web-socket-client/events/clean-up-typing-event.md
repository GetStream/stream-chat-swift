---
title: CleanUpTypingEvent
---

A special event type which is only emitted by the SDK and never the backend.
This event is emitted by `TypingStartCleanupMiddleware` to signal that a typing event
must be cleaned up, due to timeout of that event.

``` swift
public struct CleanUpTypingEvent: Event 
```

## Inheritance

`Equatable`, [`Event`](../event)

## Properties

### `cid`

``` swift
public let cid: ChannelId
```

### `userId`

``` swift
public let userId: UserId
```

## Operators

### `==`

``` swift
public static func == (lhs: CleanUpTypingEvent, rhs: CleanUpTypingEvent) -> Bool 
```
