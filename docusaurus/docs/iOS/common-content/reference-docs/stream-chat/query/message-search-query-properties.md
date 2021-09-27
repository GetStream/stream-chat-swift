
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
