
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
