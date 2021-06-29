---
title: ChannelListQuery
---

A query is used for querying specific channels from backend.
You can specify filter, sorting, pagination, limit for fetched messages in channel and other options.

``` swift
public struct _ChannelListQuery<ExtraData: ChannelExtraData>: Encodable 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

`Encodable`, `Equatable`

## Initializers

### `init(filter:sort:pageSize:messagesLimit:)`

Init a channels query.

``` swift
public init(
        filter: Filter<_ChannelListFilterScope<ExtraData>>,
        sort: [Sorting<ChannelListSortingKey>] = [],
        pageSize: Int = .channelsPageSize,
        messagesLimit: Int = .messagesPageSize
    ) 
```

#### Parameters

  - filter: a channels filter.
  - sort: a sorting list for channels.
  - pageSize: a page size for pagination.
  - messagesLimit: a number of messages for the channel to be retrieved.

## Properties

### `filter`

A filter for the query (see `Filter`).

``` swift
public let filter: Filter<_ChannelListFilterScope<ExtraData>>
```

### `sort`

A sorting for the query (see `Sorting`).

``` swift
public let sort: [Sorting<ChannelListSortingKey>]
```

### `pagination`

A pagination.

``` swift
public var pagination: Pagination
```

### `messagesLimit`

A number of messages inside each channel.

``` swift
public let messagesLimit: Int
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```

## Operators

### `==`

``` swift
public static func == (lhs: _ChannelListQuery<ExtraData>, rhs: _ChannelListQuery<ExtraData>) -> Bool 
```
