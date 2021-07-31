---
title: TypingSuggestion
---

A structure that contains the information of the typing suggestion.

``` swift
public struct TypingSuggestion 
```

## Initializers

### `init(text:locationRange:)`

The typing suggestion info.

``` swift
public init(text: String, locationRange: NSRange) 
```

#### Parameters

  - text: A String representing the currently typing text.
  - locationRange: A NSRange that stores the location of the typing suggestion in relation with the whole input.

## Properties

### `text`

A String representing the currently typing text.

``` swift
public let text: String
```

### `locationRange`

A NSRange that stores the location of the typing suggestion in relation with the whole input.

``` swift
public let locationRange: NSRange
```
