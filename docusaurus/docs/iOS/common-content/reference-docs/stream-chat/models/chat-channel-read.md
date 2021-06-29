---
title: ChatChannelRead
---

A type representing a user's last read action on a channel.

``` swift
public struct _ChatChannelRead<ExtraData: ExtraDataTypes> 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Properties

### `lastReadAt`

The last time the user has read the channel.

``` swift
public let lastReadAt: Date
```

### `unreadMessagesCount`

Number of unread messages the user has in this channel.

``` swift
public let unreadMessagesCount: Int
```

### `user`

The user who read the channel.

``` swift
public let user: _ChatUser<ExtraData.User>
```
