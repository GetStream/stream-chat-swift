---
id: messagenewevent 
title: MessageNewEvent
slug: /ReferenceDocs/Sources/StreamChat/WebSocketClient/Events/messagenewevent
---

``` swift
public struct MessageNewEvent: MessageSpecificEvent 
```

## Inheritance

[`MessageSpecificEvent`](MessageSpecificEvent)

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
