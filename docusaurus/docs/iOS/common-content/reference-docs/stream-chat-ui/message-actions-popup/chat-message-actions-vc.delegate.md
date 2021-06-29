---
title: ChatMessageActionsVC.Delegate
---

Delegate instance for `_ChatMessageActionsVC`.

``` swift
struct Delegate 
```

## Initializers

### `init(didTapOnActionItem:didFinish:)`

Init of `_ChatMessageActionsVC.Delegate`.

``` swift
public init(
            didTapOnActionItem: @escaping (_ChatMessageActionsVC, _ChatMessage<ExtraData>, ChatMessageActionItem)
                -> Void = { _, _, _ in },
            didFinish: @escaping (_ChatMessageActionsVC) -> Void = { _ in }
        ) 
```

### `init(delegate:)`

Wraps `_ChatMessageActionsVCDelegate` into `_ChatMessageActionsVC.Delegate`.

``` swift
public init<Delegate: _ChatMessageActionsVCDelegate>(delegate: Delegate) where Delegate.ExtraData == ExtraData 
```

## Properties

### `didTapOnActionItem`

Triggered when action item was tapped.
You can decide what to do with message based on which instance of `ChatMessageActionItem` you received.

``` swift
public var didTapOnActionItem: (_ChatMessageActionsVC, _ChatMessage<ExtraData>, ChatMessageActionItem) -> Void
```

### `didFinish`

Triggered when `_ChatMessageActionsVC` should be dismissed.

``` swift
public var didFinish: (_ChatMessageActionsVC) -> Void
```
