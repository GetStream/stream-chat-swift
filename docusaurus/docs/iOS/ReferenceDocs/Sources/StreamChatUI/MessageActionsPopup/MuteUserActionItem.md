---
id: muteuseractionitem 
title: MuteUserActionItem
slug: /ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/muteuseractionitem
---

Instance of `ChatMessageActionItem` for muting user.

``` swift
public struct MuteUserActionItem: ChatMessageActionItem 
```

## Inheritance

[`ChatMessageActionItem`](ChatMessageActionItem)

## Initializers

### `init(action:appearance:)`

Init of `MuteUserActionItem`.

``` swift
public init(
        action: @escaping (ChatMessageActionItem) -> Void,
        appearance: Appearance = .default
    ) 
```

#### Parameters

  - action: Action to be triggered when `MuteUserActionItem` is tapped.
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
