---
id: chatchannellistitemview.content 
title: ChatChannelListItemView.Content
--- 

The content of this view.

``` swift
public struct Content 
```

## Initializers

### `init(channel:currentUserId:)`

``` swift
public init(channel: _ChatChannel<ExtraData>, currentUserId: UserId?) 
```

## Properties

### `channel`

Channel for the current Item.

``` swift
public let channel: _ChatChannel<ExtraData>
```

### `currentUserId`

Current user ID needed to filter out when showing typing indicator.

``` swift
public let currentUserId: UserId?
```
