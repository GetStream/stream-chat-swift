---
id: userbannedevent 
title: UserBannedEvent
slug: referencedocs/sources/streamchat/websocketclient/events/userbannedevent
---

``` swift
public struct UserBannedEvent: UserSpecificEvent, ChannelSpecificEvent 
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

### `ownerId`

``` swift
public let ownerId: UserId
```

### `createdAt`

``` swift
public let createdAt: Date?
```

### `reason`

``` swift
public let reason: String?
```

### `expiredAt`

``` swift
public let expiredAt: Date?
```
