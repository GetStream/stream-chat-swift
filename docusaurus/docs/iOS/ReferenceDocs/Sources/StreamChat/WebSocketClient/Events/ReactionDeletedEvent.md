---
id: reactiondeletedevent 
title: ReactionDeletedEvent
slug: /ReferenceDocs/Sources/StreamChat/WebSocketClient/Events/reactiondeletedevent
---

``` swift
public struct ReactionDeletedEvent: ReactionEvent 
```

## Inheritance

[`ReactionEvent`](ReactionEvent)

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

### `reactionType`

``` swift
public let reactionType: MessageReactionType
```

### `reactionScore`

``` swift
public let reactionScore: Int
```
