---
title: GradientView.Content
---

A type representing gradient drawing options

``` swift
public struct Content 
```

## Initializers

### `init(direction:colors:locations:)`

``` swift
public init(
            direction: Direction,
            colors: [UIColor],
            locations: [CGFloat]? = nil
        ) 
```

## Properties

### `direction`

The gradient direction.

``` swift
public var direction: Direction
```

### `colors`

The gradient colors.

``` swift
public var colors: [UIColor]
```

### `locations`

The gradient color locations.

``` swift
public var locations: [CGFloat]?
```
