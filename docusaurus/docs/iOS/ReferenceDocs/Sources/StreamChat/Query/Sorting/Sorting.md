---
id: sorting 
title: Sorting
slug: /ReferenceDocs/Sources/StreamChat/Query/Sorting/sorting
---

Sorting options.

``` swift
public struct Sorting<Key: SortingKey>: Encodable, CustomStringConvertible 
```

For example:

``` 
// Sort channels by the last message date:
let sorting = Sorting("lastMessageDate")
```

## Inheritance

`CustomStringConvertible`, `Encodable`

## Initializers

### `init(key:isAscending:)`

Init sorting options.

``` swift
public init(key: Key, isAscending: Bool = false) 
```

#### Parameters

  - key: a sorting key.
  - isAscending: a direction of the sorting.

## Properties

### `key`

A sorting field name.

``` swift
public let key: Key
```

### `direction`

A sorting direction.

``` swift
public let direction: Int
```

### `isAscending`

True if the sorting in ascending order, otherwise false.

``` swift
public var isAscending: Bool 
```

### `description`

``` swift
public var description: String 
```
