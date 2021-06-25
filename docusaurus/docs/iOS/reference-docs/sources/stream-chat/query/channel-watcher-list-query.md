---
title: ChannelWatcherListQuery
---

A query type used for fetching a channel's watchers from the backend.

``` swift
public struct ChannelWatcherListQuery: Encodable 
```

Learn more about watchers in our documentation [here](https://getstream.io/chat/docs/ios/watch_channel/?language=swift)

## Inheritance

`Encodable`

## Initializers

### `init(cid:pagination:)`

Creates new `ChannelWatcherListQuery` instance.

``` swift
public init(cid: ChannelId, pagination: Pagination = .init(pageSize: .channelWatchersPageSize)) 
```

#### Parameters

  - cid: The channel identifier.
  - pagination: Pagination parameters for fetching watchers. Defaults to fetching first 30 watchers.

## Properties

### `pagination`

A pagination for watchers (see `Pagination`).

``` swift
public var pagination: Pagination
```

### `cid`

`ChannelId` this query handles.

``` swift
public var cid: ChannelId
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
