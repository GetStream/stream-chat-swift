---
title: MemberRemovedEvent
---

``` swift
public struct MemberRemovedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
```

## Inheritance

[`EventWithPayload`](event-with-payload.md), [`ChannelSpecificEvent`](channel-specific-event.md), [`MemberEvent`](member-event.md)

## Properties

### `memberUserId`

``` swift
public var memberUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
