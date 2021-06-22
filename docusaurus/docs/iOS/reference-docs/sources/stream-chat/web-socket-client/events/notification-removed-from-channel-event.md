---
title: NotificationRemovedFromChannelEvent
---

``` swift
public struct NotificationRemovedFromChannelEvent: CurrentUserEvent, ChannelSpecificEvent 
```

## Inheritance

[`ChannelSpecificEvent`](channel-specific-event), [`CurrentUserEvent`](current-user-event)

## Properties

### `currentUserId`

``` swift
public let currentUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
