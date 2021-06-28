---
title: DeleteActionItem
---

Instance of `ChatMessageActionItem` for deleting message action.

``` swift
public struct DeleteActionItem: ChatMessageActionItem 
```

## Inheritance

[`ChatMessageActionItem`](chat-message-action-item.md)

## Initializers

### `init(action:appearance:)`

Init of `DeleteActionItem`.

``` swift
public init(
        action: @escaping (ChatMessageActionItem) -> Void,
        appearance: Appearance = .default
    ) 
```

#### Parameters

  - action: Action to be triggered when `DeleteActionItem` is tapped.
  - appearance: `Appearance` that is used to configure UI properties.

## Properties

### `title`

``` swift
public var title: String 
```

### `isDestructive`

``` swift
public var isDestructive: Bool 
```

### `icon`

``` swift
public let icon: UIImage
```

### `action`

``` swift
public let action: (ChatMessageActionItem) -> Void
```
