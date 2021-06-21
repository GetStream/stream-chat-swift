---
id: reactionnewevent 
title: ReactionNewEvent
slug: referencedocs/sources/streamchat/websocketclient/events/reactionnewevent
---

``` swift
public struct ReactionNewEvent: ReactionEvent 
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

### `createdAt`

``` swift
public let createdAt: Date
```
