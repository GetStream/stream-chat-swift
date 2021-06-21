---
id: userlistsortingkey 
title: UserListSortingKey
--- 

`UserListSortingKey` is keys by which you can get sorted users after query.

``` swift
public enum UserListSortingKey: String, SortingKey 
```

## Inheritance

[`SortingKey`](SortingKey), `String`

## Enumeration Cases

### `id`

Sort users by id.

``` swift
case id
```

### `name`

Sort users by name.

``` swift
case name
```

### `role`

Sort users by role. (`user`, `admin`, `guest`, `anonymous`)

``` swift
case role = "userRoleRaw"
```

### `isBanned`

Sort users by ban status.

``` swift
case isBanned
```

### `lastActivityAt`

Sort users by last activity date.

``` swift
case lastActivityAt
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
