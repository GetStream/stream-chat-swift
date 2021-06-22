---
id: paginationparameter 
title: PaginationParameter
slug: /ReferenceDocs/Sources/StreamChat/Query/paginationparameter
---

Pagination parameters

``` swift
public enum PaginationParameter: Encodable, Hashable 
```

## Inheritance

`Encodable`, `Hashable`

## Enumeration Cases

### `greaterThan`

Filter on ids greater than the given value.

``` swift
case greaterThan(_ id: String)
```

### `greaterThanOrEqual`

Filter on ids greater than or equal to the given value.

``` swift
case greaterThanOrEqual(_ id: String)
```

### `lessThan`

Filter on ids smaller than the given value.

``` swift
case lessThan(_ id: String)
```

### `lessThanOrEqual`

Filter on ids smaller than or equal to the given value.

``` swift
case lessThanOrEqual(_ id: String)
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```

## Operators

### `==`

``` swift
public static func == (lhs: Self, rhs: Self) -> Bool 
```
