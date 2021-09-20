---
title: ChatMessageControllerDelegate
---

`ChatMessageControllerDelegate` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatMessageControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Requirements

### messageController(\_:​didChangeMessage:​)

The controller observed a change in the `ChatMessage` its observes.

``` swift
func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    )
```

### messageController(\_:​didChangeReplies:​)

The controller observed changes in the replies of the observed `ChatMessage`.

``` swift
func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    )
```
