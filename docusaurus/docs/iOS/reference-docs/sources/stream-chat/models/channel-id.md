---
title: ChannelId
---

A type representing a unique identifier of a `ChatChannel`.

``` swift
public struct ChannelId: Hashable, CustomStringConvertible 
```

It reflects channel's type and a unique id.

## Inheritance

[`APIPathConvertible`](../api-client/api-path-convertible), `Codable`, `CustomStringConvertible`, `Hashable`

## Initializers

### `init(type:id:)`

Creates a new `ChannelId` value.

``` swift
public init(type: ChannelType, id: String) 
```

#### Parameters

  - type: A type of the channel the `ChannelId` represents.
  - id: An id of the channel the `ChannelId` represents.

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `description`

``` swift
public var description: String 
```

### `type`

The type of the channel the id belongs to.

``` swift
var type: ChannelType 
```

### `id`

The id of the channel without the encoded type information.

``` swift
var id: String 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
