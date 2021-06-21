---
id: memberupdatedevent 
title: MemberUpdatedEvent
slug: referencedocs/sources/streamchat/websocketclient/events/memberupdatedevent
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
