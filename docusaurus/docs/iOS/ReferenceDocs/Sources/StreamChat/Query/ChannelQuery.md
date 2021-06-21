---
id: channelquery 
title: ChannelQuery
slug: referencedocs/sources/streamchat/query/channelquery
---

A channel query.

``` swift
public struct _ChannelQuery<ExtraData: ExtraDataTypes>: Encodable 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`APIPathConvertible`](../APIClient/APIPathConvertible), `Encodable`

## Initializers

### `init(cid:pageSize:paginationParameter:membersLimit:watchersLimit:)`

Init a channel query.

``` swift
public init(
        cid: ChannelId,
        pageSize: Int? = .messagesPageSize,
        paginationParameter: PaginationParameter? = nil,
        membersLimit: Int? = nil,
        watchersLimit: Int? = nil
    ) 
```

#### Parameters

  - cid: a channel cid.
  - pageSize: a page size for pagination.
  - paginationOptions: an advanced options for pagination. (see `PaginationOption`)
  - membersLimit: a number of members for the channel  to be retrieved.
  - watchersLimit: a number of watchers for the channel to be retrieved.

## Properties

### `id`

Channel id this query handles.

``` swift
public let id: String?
```

### `type`

Channel type this query handles.

``` swift
public let type: ChannelType
```

### `pagination`

A pagination for messages (see `MessagesPagination`).

``` swift
public var pagination: MessagesPagination?
```

### `membersLimit`

A number of members for the channel to be retrieved.

``` swift
public let membersLimit: Int?
```

### `watchersLimit`

A number of watchers for the channel to be retrieved.

``` swift
public let watchersLimit: Int?
```

### `cid`

`ChannelId` this query handles.
If `id` part is missing then it's impossible to create valid `ChannelId`.

``` swift
public var cid: ChannelId? 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
