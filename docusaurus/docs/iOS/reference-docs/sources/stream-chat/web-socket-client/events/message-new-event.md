---
title: MessageNewEvent
---

``` swift
public struct MessageNewEvent: MessageSpecificEvent 
```

## Inheritance

[`MessageSpecificEvent`](message-specific-event.md)

## Properties

### `userId`

``` swift
public let userId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```

### `messageId`

``` swift
public let messageId: MessageId
```

### `createdAt`

``` swift
public let createdAt: Date
```

### `watcherCount`

``` swift
public let watcherCount: Int?
```

### `unreadCount`

``` swift
public let unreadCount: UnreadCount?
```
