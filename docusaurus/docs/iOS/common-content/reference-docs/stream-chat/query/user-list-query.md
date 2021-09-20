---
title: UserListQuery
---

A query is used for querying specific users from backend.
You can specify filter, sorting and pagination.

``` swift
public struct UserListQuery: Encodable 
```

## Inheritance

`Encodable`

## Initializers

### `init(filter:sort:pageSize:)`

Init a users query.

``` swift
public init(
        filter: Filter<UserListFilterScope>? = nil,
        sort: [Sorting<UserListSortingKey>] = [],
        pageSize: Int = .usersPageSize
    ) 
```

#### Parameters

  - filter: a users filter. Empty filter will return all users.
  - sort: a sorting list for users.
  - pageSize: a page size for pagination.

## Properties

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
```
