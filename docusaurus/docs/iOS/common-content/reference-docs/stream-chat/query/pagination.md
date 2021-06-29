---
title: Pagination
---

Basic pagination with `pageSize` and `offset`.
Used everywhere except `ChannelQuery`. (See `MessagesPagination`)

``` swift
public struct Pagination: Encodable, Equatable 
```

## Inheritance

`Encodable`, `Equatable`

## Initializers

### `init(pageSize:offset:)`

``` swift
public init(pageSize: Int, offset: Int = 0) 
```

## Properties

### `pageSize`

A page size.

``` swift
public let pageSize: Int
```

### `offset`

An offset.

``` swift
public let offset: Int
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
