---
id: notificationmarkreadevent 
title: NotificationMarkReadEvent
slug: referencedocs/sources/streamchat/websocketclient/events/notificationmarkreadevent
---

``` swift
public struct NotificationMarkReadEvent: UserSpecificEvent, ChannelSpecificEvent 
```

## Inheritance

[`UserSpecificEvent`](UserSpecificEvent), [`ChannelSpecificEvent`](ChannelSpecificEvent)

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
public let unreadCount: UnreadCount
```
