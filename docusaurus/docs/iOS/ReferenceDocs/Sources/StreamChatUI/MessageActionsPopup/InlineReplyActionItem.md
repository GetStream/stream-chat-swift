
Instance of `ChatMessageActionItem` for inline reply.

``` swift
public struct InlineReplyActionItem: ChatMessageActionItem 
```

## Inheritance

[`ChatMessageActionItem`](ChatMessageActionItem)

## Initializers

### `init(action:appearance:)`

Init of `InlineReplyActionItem`.

``` swift
public init(
        action: @escaping (ChatMessageActionItem) -> Void,
        appearance: Appearance = .default
    ) 
```

#### Parameters

  - action: Action to be triggered when `InlineReplyActionItem` is tapped.
  - appearance: `Appearance` that is used to configure UI properties.

## Properties

### `title`

``` swift
public var title: String 
```

### `icon`

``` swift
public let icon: UIImage
```

### `action`

``` swift
public let action: (ChatMessageActionItem) -> Void
```
