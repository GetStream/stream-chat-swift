---
title: ChatChannelListItemView.Content
---

The content of this view.

``` swift
public struct Content 
```

## Initializers

### `init(channel:currentUserId:)`

``` swift
public init(channel: ChatChannel, currentUserId: UserId?) 
```

## Properties

### `channel`

Channel for the current Item.

``` swift
public let channel: ChatChannel
```

### `currentUserId`

Current user ID needed to filter out when showing typing indicator.

``` swift
public let currentUserId: UserId?
```
