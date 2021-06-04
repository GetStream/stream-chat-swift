
A parent protocol for all extra data protocols. Not meant to be adopted directly.

``` swift
public protocol ExtraData: Codable & Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Requirements

### defaultValue

Returns an `ExtraData` instance with default parameters.

``` swift
static var defaultValue: Self 
```
