---
title: ChannelMemberListQuery
---

A query type used for fetching channel members from the backend.

``` swift
public struct ChannelMemberListQuery: Encodable 
```

## Inheritance

`Encodable`

## Initializers

### `init(cid:filter:sort:pageSize:)`

Creates new `ChannelMemberListQuery` instance.

``` swift
public init(
        cid: ChannelId,
        filter: Filter<MemberListFilterScope>? = nil,
        sort: [Sorting<ChannelMemberListSortingKey>] = [],
        pageSize: Int = .channelMembersPageSize
    ) 
```

#### Parameters

  - cid: The channel identifier.
  - filter: The members filter. Empty filter will return all users.
  - sort: The sorting for members list.
  - pageSize: The page size for pagination.

## Properties

### `cid`

A channel identifier the members should be fetched for.

``` swift
public let cid: ChannelId
```

### `filter`

A filter for the query (see `Filter`).

``` swift
public let filter: Filter<MemberListFilterScope>?
```

### `sort`

A sorting for the query (see `Sorting`).

``` swift
public let sort: [Sorting<ChannelMemberListSortingKey>]
```

### `pagination`

A pagination.

``` swift
public var pagination: Pagination
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
