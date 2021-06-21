---
id: memberupdatedevent 
title: MemberUpdatedEvent
--- 

``` swift
public struct MemberUpdatedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
```

## Inheritance

[`EventWithPayload`](EventWithPayload), [`ChannelSpecificEvent`](ChannelSpecificEvent), [`MemberEvent`](MemberEvent)

## Properties

### `memberUserId`

``` swift
public let memberUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
