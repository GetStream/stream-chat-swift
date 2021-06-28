---
title: MemberAddedEvent
---

``` swift
public struct MemberAddedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
```

## Inheritance

[`EventWithPayload`](event-with-payload.md), [`ChannelSpecificEvent`](channel-specific-event.md), [`MemberEvent`](member-event.md)

## Properties

### `memberUserId`

``` swift
public let memberUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
