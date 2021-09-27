
### `filter`

A filter for the query (see `Filter`).

``` swift
public var filter: Filter<UserListFilterScope>?
```

### `sort`

A sorting for the query (see `Sorting`).

``` swift
public let sort: [Sorting<UserListSortingKey>]
```

### `pagination`

A pagination.

``` swift
public var pagination: Pagination?
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
