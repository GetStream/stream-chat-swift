---
id: channelunreadcount 
title: ChannelUnreadCount
slug: referencedocs/sources/streamchat/models/channelunreadcount
---

A struct describing unread counts for a channel.

``` swift
public struct ChannelUnreadCount: Decodable, Equatable 
```

## Inheritance

`Decodable`, `Equatable`

## Properties

### `noUnread`

The default value representing no unread messages.

``` swift
public static let noUnread 
```

### `messages`

The total number of unread messages in the channel.

``` swift
public internal(set) var messages: Int
```

### `mentionedMessages`

The number of unread messages that mention the current user.

``` swift
public internal(set) var mentionedMessages: Int
```
