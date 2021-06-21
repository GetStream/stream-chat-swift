---
id: userunbannedevent 
title: UserUnbannedEvent
slug: referencedocs/sources/streamchat/websocketclient/events/userunbannedevent
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
