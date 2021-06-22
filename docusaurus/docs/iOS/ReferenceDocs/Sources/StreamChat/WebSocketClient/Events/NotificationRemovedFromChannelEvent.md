---
id: notificationremovedfromchannelevent 
title: NotificationRemovedFromChannelEvent
slug: /ReferenceDocs/Sources/StreamChat/WebSocketClient/Events/notificationremovedfromchannelevent
---

``` swift
public struct NotificationRemovedFromChannelEvent: CurrentUserEvent, ChannelSpecificEvent 
```

## Inheritance

[`ChannelSpecificEvent`](ChannelSpecificEvent), [`CurrentUserEvent`](CurrentUserEvent)

## Properties

### `currentUserId`

``` swift
public let currentUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
