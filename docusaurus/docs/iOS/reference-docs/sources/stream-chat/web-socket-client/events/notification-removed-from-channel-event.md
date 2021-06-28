---
title: NotificationRemovedFromChannelEvent
---

``` swift
public struct NotificationRemovedFromChannelEvent: CurrentUserEvent, ChannelSpecificEvent 
```

## Inheritance

[`ChannelSpecificEvent`](channel-specific-event.md), [`CurrentUserEvent`](current-user-event.md)

## Properties

### `currentUserId`

``` swift
public let currentUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
