---
title: UserBannedEvent
---

``` swift
public struct UserBannedEvent: UserSpecificEvent, ChannelSpecificEvent 
```

## Inheritance

[`UserSpecificEvent`](user-specific-event), [`ChannelSpecificEvent`](channel-specific-event)

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
