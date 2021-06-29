---
title: ContainerStackView.Spacing
---

Describes the Spacing between the arranged subviews.

``` swift
public struct Spacing: Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral 
```

## Inheritance

`Equatable`, `ExpressibleByFloatLiteral`, `ExpressibleByIntegerLiteral`

## Initializers

### `init(floatLiteral:)`

`Spacing` can be expressed by a `Double`.
Example:​ `spacing = 10.0`, instead of `spacing = Spacing(10.0)`.

``` swift
public init(floatLiteral value: Double) 
```

### `init(integerLiteral:)`

`Spacing` can be expressed by an `Int`.
Example:​ `spacing = 10`, instead of `spacing = Spacing(10)`.

``` swift
public init(integerLiteral value: Int) 
```

### `init(_:)`

``` swift
public init(_ rawValue: CGFloat) 
```

## Properties

### `rawValue`

The actual value of the Spacing.

``` swift
public var rawValue: CGFloat
```

### `auto`

The default system spacing between the arranged subviews.
Example:​ `spacing = .auto`.

``` swift
public static let auto 
```
