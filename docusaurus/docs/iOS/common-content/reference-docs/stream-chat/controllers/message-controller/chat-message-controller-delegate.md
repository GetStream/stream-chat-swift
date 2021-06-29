---
title: ChatMessageControllerDelegate
---

`_ChatMessageControllerDelegate` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatMessageControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatMessageControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Default Implementations

### `messageController(_:didChangeMessage:)`

``` swift
func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) 
```

### `messageController(_:didChangeReplies:)`

``` swift
func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### messageController(\_:​didChangeMessage:​)

The controller observed a change in the `ChatMessage` its observes.

``` swift
func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    )
```

### messageController(\_:​didChangeReplies:​)

The controller observed changes in the replies of the observed `ChatMessage`.

``` swift
func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    )
```
