
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

