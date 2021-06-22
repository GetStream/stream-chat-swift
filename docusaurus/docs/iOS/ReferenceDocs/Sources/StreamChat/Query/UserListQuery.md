---
id: userlistquery 
title: UserListQuery
slug: /ReferenceDocs/Sources/StreamChat/Query/userlistquery
---

A query is used for querying specific users from backend.
You can specify filter, sorting and pagination.

``` swift
public struct _UserListQuery<ExtraData: UserExtraData>: Encodable 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

`Encodable`

## Initializers

### `init(filter:sort:pageSize:)`

Init a users query.

``` swift
public init(
        filter: Filter<_UserListFilterScope<ExtraData>>? = nil,
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
public var filter: Filter<_UserListFilterScope<ExtraData>>?
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
