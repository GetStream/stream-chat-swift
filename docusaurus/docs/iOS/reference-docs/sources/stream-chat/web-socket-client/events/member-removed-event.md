---
title: MemberRemovedEvent
---

``` swift
public struct MemberRemovedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
```

## Inheritance

[`EventWithPayload`](event-with-payload), [`ChannelSpecificEvent`](channel-specific-event), [`MemberEvent`](member-event)

## Properties

### `memberUserId`

``` swift
public var memberUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
