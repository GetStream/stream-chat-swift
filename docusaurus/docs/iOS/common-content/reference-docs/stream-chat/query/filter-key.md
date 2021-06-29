---
title: FilterKey
---

A helper struct that represents a key of a filter.

``` swift
public struct FilterKey<Scope: FilterScope, Value: FilterValue>: ExpressibleByStringLiteral, RawRepresentable 
```

It allows tagging a key with a scope and a type of the value the key is related to.

Learn more about how to create filter keys for your custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#query-filters).

## Inheritance

`ExpressibleByStringLiteral`, `RawRepresentable`

## Initializers

### `init(stringLiteral:)`

``` swift
public init(stringLiteral value: String) 
```

### `init(rawValue:)`

``` swift
public init(rawValue value: String) 
```

## Properties

### `rawValue`

The raw value of the key. This value should match the "encodable" key for the given object.

``` swift
public let rawValue: String
```
