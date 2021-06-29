
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
