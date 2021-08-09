---
title: TypingSuggestionOptions
---

The options to configure the `TypingSuggester`.

``` swift
public struct TypingSuggestionOptions 
```

## Initializers

### `init(symbol:shouldTriggerOnlyAtStart:minimumRequiredCharacters:)`

The options to configure the `TypingSuggester`.

``` swift
public init(
        symbol: String,
        shouldTriggerOnlyAtStart: Bool = false,
        minimumRequiredCharacters: Int = 0
    ) 
```

#### Parameters

  - symbol: A String describing the symbol that typing suggester will use to recognise a suggestion.
  - shouldTriggerOnlyAtStart: A Boolean value to determine if suggester should only be recognising at the start of the input. By default it is `false`.
  - minimumRequiredCharacters: The minimum required characters for the suggester to start recognising a suggestion. By default it is `0`, so the suggester will recognise once the symbol is typed.

## Properties

### `symbol`

The symbol that typing suggester will use to recognise a suggestion.

``` swift
public var symbol: String
```

### `shouldTriggerOnlyAtStart`

Wether the suggester should only be recognising at the start of the input.

``` swift
public var shouldTriggerOnlyAtStart: Bool
```

### `minimumRequiredCharacters`

The minimum required characters for the suggester to start recognising a suggestion.

``` swift
public var minimumRequiredCharacters: Int
```
