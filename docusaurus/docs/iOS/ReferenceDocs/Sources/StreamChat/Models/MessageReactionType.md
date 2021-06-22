---
id: messagereactiontype 
title: MessageReactionType
slug: /ReferenceDocs/Sources/StreamChat/Models/messagereactiontype
---

The type that describes a message reaction type.

``` swift
public struct MessageReactionType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral 
```

The reaction has underlaying type `String` what gives the flexibility to choose the way how the reaction
will be displayed in the application.

Common examples are: "like", "love", "smile", etc.

## Inheritance

`Codable`, `ExpressibleByStringLiteral`, `Hashable`, `RawRepresentable`

## Initializers

### `init(rawValue:)`

``` swift
public init(rawValue: String) 
```

### `init(stringLiteral:)`

``` swift
public init(stringLiteral: String) 
```

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `rawValue`

``` swift
public let rawValue: String
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
