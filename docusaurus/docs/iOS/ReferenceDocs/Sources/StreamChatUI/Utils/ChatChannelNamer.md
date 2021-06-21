---
id: chatchannelnamer 
title: ChatChannelNamer
--- 

Typealias for closure taking `_ChatChannel<ExtraData>` and `UserId` which returns
the current name of the channel. Use this type when you create closure for naming a channel.
For example usage, see `DefaultChatChannelNamer`

``` swift
public typealias _ChatChannelNamer<ExtraData: ExtraDataTypes> =
    (_ channel: _ChatChannel<ExtraData>, _ currentUserId: UserId?) -> String?
```
