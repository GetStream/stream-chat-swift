---
id: resendactionitem 
title: ResendActionItem
slug: /ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/resendactionitem
---

Instance of `ChatMessageActionItem` for resending message action.

``` swift
public struct ResendActionItem: ChatMessageActionItem 
```

## Inheritance

[`ChatMessageActionItem`](ChatMessageActionItem)

## Initializers

### `init(action:appearance:)`

Init of `ResendActionItem`.

``` swift
public init(
        action: @escaping (ChatMessageActionItem) -> Void,
        appearance: Appearance = .default
    ) 
```

#### Parameters

  - action: Action to be triggered when `ResendActionItem` is tapped.
  - appearance: `Appearance` that is used to configure UI properties.

## Properties

### `title`

``` swift
public var title: String 
```

### `isPrimary`

``` swift
public var isPrimary: Bool 
```

### `icon`

``` swift
public let icon: UIImage
```

### `action`

``` swift
public let action: (ChatMessageActionItem) -> Void
```
