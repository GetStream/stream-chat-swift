---
title: RawJSON
---

A `RawJSON` type.
Used to store and operate objects of unknown structure that's not possible to decode.
https:​//forums.swift.org/t/new-unevaluated-type-for-decoder-to-allow-later-re-encoding-of-data-with-unknown-structure/11117

``` swift
public indirect enum RawJSON: Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Enumeration Cases

### `number`

``` swift
case number(Double)
```

### `string`

``` swift
case string(String)
```

### `bool`

``` swift
case bool(Bool)
```

### `dictionary`

``` swift
case dictionary([String: RawJSON])
```

### `array`

``` swift
case array([RawJSON])
```

### `` `nil` ``

``` swift
case `nil`
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```

### `dictionary(with:forKey:)`

``` swift
func dictionary(with value: RawJSON?, forKey key: String) -> RawJSON? 
```
