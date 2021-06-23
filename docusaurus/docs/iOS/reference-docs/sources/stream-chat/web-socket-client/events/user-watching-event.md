---
title: UserWatchingEvent
---

``` swift
public struct UserWatchingEvent: UserSpecificEvent, ChannelSpecificEvent 
```

## Inheritance

[`UserSpecificEvent`](../user-specific-event), [`ChannelSpecificEvent`](../channel-specific-event)

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
public let createdAt: Date
```

### `watcherCount`

``` swift
public let watcherCount: Int
```

### `isStarted`

``` swift
public let isStarted: Bool
```
