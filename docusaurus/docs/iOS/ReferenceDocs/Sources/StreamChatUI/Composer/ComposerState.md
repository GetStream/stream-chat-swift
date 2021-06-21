---
id: composerstate 
title: ComposerState
--- 

The possible composer states. An Enum is not used so it does not cause
future breaking changes and is possible to extend with new cases.

``` swift
public struct ComposerState: RawRepresentable, Equatable 
```

## Inheritance

`Equatable`, `RawRepresentable`

## Initializers

### `init(rawValue:)`

``` swift
public init(rawValue: RawValue) 
```

## Properties

### `rawValue`

``` swift
public let rawValue: String
```

### `description`

``` swift
public var description: String 
```

### `new`

``` swift
public static var new 
```

### `edit`

``` swift
public static var edit 
```

### `quote`

``` swift
public static var quote 
```
