---
title: UnmuteUserActionItem
---

Instance of `ChatMessageActionItem` for un-muting user.

``` swift
public struct UnmuteUserActionItem: ChatMessageActionItem 
```

## Inheritance

[`ChatMessageActionItem`](../chat-message-action-item)

## Initializers

### `init(action:appearance:)`

Init of `UnmuteUserActionItem`.

``` swift
public init(
        action: @escaping (ChatMessageActionItem) -> Void,
        appearance: Appearance = .default
    ) 
```

#### Parameters

  - `action`: Action to be triggered when `UnmuteUserActionItem` is tapped.
  - `appearance`: `Appearance` that is used to configure UI properties.

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
