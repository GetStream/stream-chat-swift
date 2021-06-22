---
id: messagedeletedevent 
title: MessageDeletedEvent
slug: /ReferenceDocs/Sources/StreamChat/WebSocketClient/Events/messagedeletedevent
---

``` swift
public struct MessageDeletedEvent: MessageSpecificEvent 
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

### `deletedAt`

``` swift
public let deletedAt: Date
```
