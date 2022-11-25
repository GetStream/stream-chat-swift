---
title: Command
---

A command in a message, for example /giphy.

``` swift
public struct Command: Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Initializers

### `init(name:description:set:args:)`

``` swift
public init(name: String = "", description: String = "", set: String = "", args: String = "") 
```

## Properties

### `name`

A command name.

``` swift
public let name: String
```

### `description`

A description.

``` swift
public let description: String
```

### `set`

``` swift
public let set: String
```

### `args`

Arguments for the command.

``` swift
public let args: String
```
