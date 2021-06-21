---
id: memberaddedevent 
title: MemberAddedEvent
slug: referencedocs/sources/streamchat/websocketclient/events/memberaddedevent
---

``` swift
public struct MemberAddedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload 
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
