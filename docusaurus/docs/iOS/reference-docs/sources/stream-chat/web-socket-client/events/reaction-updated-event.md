---
title: ReactionUpdatedEvent
---

``` swift
public struct ReactionUpdatedEvent: ReactionEvent 
```

## Inheritance

[`ReactionEvent`](../reaction-event)

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

### `updatedAt`

``` swift
public let updatedAt: Date
```
