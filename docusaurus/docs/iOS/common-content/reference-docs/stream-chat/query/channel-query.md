---
title: ChannelQuery
---

A channel query.

``` swift
public struct ChannelQuery: Encodable 
```

## Inheritance

[`APIPathConvertible`](../../api-client/api-path-convertible), `Encodable`

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
  - paginationParameter: the pagination configuration.
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
