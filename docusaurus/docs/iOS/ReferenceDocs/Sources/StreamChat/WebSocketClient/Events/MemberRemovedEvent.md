---
id: memberremovedevent 
title: MemberRemovedEvent
slug: referencedocs/sources/streamchat/websocketclient/events/memberremovedevent
---

``` swift
public struct MemberRemovedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
```

## Inheritance

[`EventWithPayload`](EventWithPayload), [`ChannelSpecificEvent`](ChannelSpecificEvent), [`MemberEvent`](MemberEvent)

## Properties

### `memberUserId`

``` swift
public var memberUserId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```
