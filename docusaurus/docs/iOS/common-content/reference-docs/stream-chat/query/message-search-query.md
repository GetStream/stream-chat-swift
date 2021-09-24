---
title: MessageSearchQuery
---

``` swift
public struct MessageSearchQuery: Encodable 
```

## Inheritance

`Encodable`

## Initializers

### `init(channelFilter:messageFilter:sort:pageSize:)`

``` swift
public init(
        channelFilter: Filter<ChannelListFilterScope>,
        messageFilter: Filter<MessageSearchFilterScope>,
        sort: [Sorting<MessageSearchSortingKey>] = [],
        pageSize: Int = .messagesPageSize
    ) 
```

## Properties

### `channelFilter`

``` swift
public let channelFilter: Filter<ChannelListFilterScope>
```

### `messageFilter`

``` swift
public let messageFilter: Filter<MessageSearchFilterScope>
```

### `sort`

``` swift
public let sort: [Sorting<MessageSearchSortingKey>]
```

### `pagination`

``` swift
public var pagination: Pagination?
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
