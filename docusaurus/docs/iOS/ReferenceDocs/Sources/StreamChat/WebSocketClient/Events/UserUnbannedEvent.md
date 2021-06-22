---
id: userunbannedevent 
title: UserUnbannedEvent
slug: /ReferenceDocs/Sources/StreamChat/WebSocketClient/Events/userunbannedevent
---

``` swift
public struct UserUnbannedEvent: UserSpecificEvent, ChannelSpecificEvent 
```

## Inheritance

[`UserSpecificEvent`](UserSpecificEvent), [`ChannelSpecificEvent`](ChannelSpecificEvent)

## Properties

### `cid`

``` swift
public let cid: ChannelId
```

### `userId`

``` swift
public let userId: UserId
```

### `createdAt`

``` swift
public let createdAt: Date?
```
