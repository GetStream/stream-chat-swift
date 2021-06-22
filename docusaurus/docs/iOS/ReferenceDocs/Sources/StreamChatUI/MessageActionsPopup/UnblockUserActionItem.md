---
id: unblockuseractionitem 
title: UnblockUserActionItem
slug: /ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/unblockuseractionitem
---

Instance of `ChatMessageActionItem` for unblocking user.

``` swift
public struct UnblockUserActionItem: ChatMessageActionItem 
```

## Inheritance

[`ChatMessageActionItem`](ChatMessageActionItem)

## Initializers

### `init(action:appearance:)`

Init of `UnblockUserActionItem`.

``` swift
public init(
        action: @escaping (ChatMessageActionItem) -> Void,
        appearance: Appearance = .default
    ) 
```

#### Parameters

  - action: Action to be triggered when `UnblockUserActionItem` is tapped.
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
