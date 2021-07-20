---
title: TypingEvent
---

``` swift
public struct TypingEvent: UserSpecificEvent, ChannelSpecificEvent 
```

## Inheritance

`Equatable`, [`UserSpecificEvent`](../user-specific-event), [`ChannelSpecificEvent`](../channel-specific-event)

## Properties

### `isTyping`

``` swift
public let isTyping: Bool
```

### `cid`

``` swift
public let cid: ChannelId
```

### `userId`

``` swift
public let userId: UserId
```

### `parentId`

``` swift
public let parentId: MessageId?
```

### `isThread`

``` swift
public let isThread: Bool
```

## Operators

### `==`

``` swift
public static func == (lhs: TypingEvent, rhs: TypingEvent) -> Bool 
```
