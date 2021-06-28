---
title: MessageReadEvent
---

`ChannelReadEvent`, this event tells that User has mark read all messages in channel.

``` swift
public struct MessageReadEvent: UserSpecificEvent, ChannelSpecificEvent 
```

## Inheritance

[`UserSpecificEvent`](user-specific-event.md), [`ChannelSpecificEvent`](channel-specific-event.md)

## Properties

### `userId`

``` swift
public let userId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```

### `readAt`

``` swift
public let readAt: Date
```

### `unreadCount`

``` swift
public let unreadCount: UnreadCount?
```
