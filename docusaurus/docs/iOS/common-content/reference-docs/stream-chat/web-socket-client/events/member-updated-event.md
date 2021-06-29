---
title: MemberUpdatedEvent
---

``` swift
public struct MemberUpdatedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
```

## Inheritance

[`EventWithPayload`](../event-with-payload), [`ChannelSpecificEvent`](../channel-specific-event), [`MemberEvent`](../member-event)

## Properties

### `memberUserId`

``` swift
public let memberUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
