---
title: TypingSuggester
---

A component responsible for finding typing suggestions in a `UITextView`.

``` swift
public struct TypingSuggester 
```

## Initializers

### `init(options:)`

``` swift
public init(options: TypingSuggestionOptions) 
```

## Properties

### `options`

The structure that contains the suggestion configuration.

``` swift
public let options: TypingSuggestionOptions
```

## Methods

### `typingSuggestion(in:)`

Checks if the user typed the recognising symbol and returns the typing suggestion.

``` swift
public func typingSuggestion(in textView: UITextView) -> TypingSuggestion? 
```

#### Parameters

  - textView: The `UITextView` the user is currently typing.

#### Returns

The typing suggestion if it was recognised, `nil` otherwise.
