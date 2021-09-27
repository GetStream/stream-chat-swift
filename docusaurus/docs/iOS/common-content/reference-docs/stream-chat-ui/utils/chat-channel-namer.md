---
title: ChatChannelNamer
---

Typealias for closure taking `ChatChannel` and `UserId` which returns
the current name of the channel. Use this type when you create closure for naming a channel.
For example usage, see `DefaultChatChannelNamer`

``` swift
public typealias ChatChannelNamer =
    (_ channel: ChatChannel, _ currentUserId: UserId?) -> String?
```
